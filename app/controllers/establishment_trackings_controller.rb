class EstablishmentTrackingsController < ApplicationController
  before_action :set_establishment, except: %i[new_by_siret index]
  before_action :set_tracking, only: %i[show destroy edit update manage_contributors update_contributors]
  before_action :set_system_labels, only: %i[new new_by_siret edit update create]

  def index
    params[:q] = handle_filters(params)

    # Storing user's layout choice (cards or table). TODO put it in the session
    @current_view = params.dig(:q, :view) || "table"

    # Removing `view` from `q` so it doesn't affect Ransack
    clean_params = params[:q]&.except(:view)

    # We don't want discarded trackings
    base_scope = policy_scope(EstablishmentTracking).kept
    @q = base_scope.ransack(clean_params)

    if params.dig(:q, :my_tracking) == '1'
      @establishment_trackings = @q.result.with_user_as_referent_or_participant(current_user)
    else
      @establishment_trackings = @q.result
    end

    @paginated_establishment_trackings = @establishment_trackings.includes(:referents, :criticality, establishment: :department).page(params[:page]).per(15)

    respond_to do |format|
      format.html
      format.xlsx do
        export_establishment_trackings(@establishment_trackings, @q)
      end
    end
  end

  def show
    user_network_ids = current_user.networks.pluck(:id) # ['CODEFI' and user's specific network]
    @summaries = Summary.where(establishment_tracking: @establishment_tracking, network_id: user_network_ids)

    @codefi_summaries = @summaries.find { |s| s.network.name == 'CODEFI' }
    @user_network_summaries = @summaries.find { |s| s.network.id == current_user.networks.where.not(name: 'CODEFI').pluck(:id).first }

    @comments = Comment.includes([:network, :user]).where(establishment_tracking: @establishment_tracking, network_id: user_network_ids).order(created_at: :desc)

    @codefi_comments = @comments.select { |c| c.network.name == 'CODEFI' }
    @user_network_comments = @comments.select { |c| c.network.id == current_user.networks.where.not(name: 'CODEFI').pluck(:id).first }

    @other_trackings = @establishment_tracking.establishment.establishment_trackings.where.not(id: @establishment_tracking.id)
  end

  def new
    @establishment_tracking = @establishment.establishment_trackings.new
    @establishment_tracking.referents << current_user
  end

  def new_by_siret
    @establishment = Establishment.find_by(siret: params[:siret])

    if @establishment
      # Check if there's an existing in-progress tracking
      active_tracking = @establishment.establishment_trackings.find_by(state: ['in_progress', 'under_surveillance'])
      if active_tracking
        redirect_to establishment_establishment_tracking_path(@establishment, active_tracking),
                    alert: "Il y a déjà un accompagnement en cours pour cet établissement."
      else
        redirect_to new_establishment_establishment_tracking_path(@establishment)
      end
    else
      department = Department.find_by(code: params[:code_departement])

      if department.nil?
        redirect_to root_path, alert: "Département introuvable avec le code #{params[:code_departement]}"
        return
      end

      siren = params[:siret][0, 9] # Les 9 premiers chiffres du SIRET sont le SIREN

      @establishment = Establishment.new(
        siret: params[:siret],
        raison_sociale: params[:denomination],
        siren: siren,
        department: department
      )

      if @establishment.save
        redirect_to new_establishment_establishment_tracking_path(@establishment),
                    notice: 'Établissement créé avec succès.'
      else
        redirect_to root_path, alert: "Impossible de créer l'établissement: #{@establishment.errors.full_messages.join(', ')}"
      end
    end
  end

  def edit
  end

  def update
    ActiveRecord::Base.transaction do
      submitted_label_ids = tracking_params[:tracking_label_ids].reject(&:blank?).map(&:to_i)

      existing_non_system_label_ids = @establishment_tracking.tracking_labels.where(system: false).pluck(:id)

      combined_label_ids = (submitted_label_ids + existing_non_system_label_ids).uniq

      params_to_update = tracking_params.except(:tracking_label_ids).merge(tracking_label_ids: combined_label_ids)

      if update_state && @establishment_tracking.update(params_to_update)
        flash[:success] = 'L\'accompagnement a été mis à jour avec succès.'
        redirect_to [@establishment, @establishment_tracking]
      else
        raise ActiveRecord::Rollback
      end
    end
  rescue ActiveRecord::Rollback
    render :edit, status: :unprocessable_entity
  end

  def create
    @establishment_tracking = @establishment.establishment_trackings.new(tracking_params)
    @establishment_tracking.creator = current_user
    @establishment_tracking.start_date ||= Date.today

    if @establishment_tracking.save
      flash[:success] = 'L\'accompagnement a été créé avec succès.'
      redirect_to @establishment
    else
      puts @establishment_tracking.errors.inspect
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @establishment = @establishment_tracking.establishment
    @establishment_tracking.destroy
    flash[:success] = 'L\'accompagnement a été supprimé avec succès.'
    redirect_to @establishment
  end

  def manage_contributors
    authorize @establishment_tracking
  end

  def update_contributors
    authorize @establishment_tracking, :manage_contributors?

    if @establishment_tracking.update(contributor_params)
      flash[:success] = "Contributeurs mis à jour avec succès."
      redirect_to [@establishment, @establishment_tracking]
    else
      flash[:error] = "Erreur lors de la mise à jour des contributeurs."
      render :manage_contributors, status: :unprocessable_entity
    end
  end

  private

  def set_establishment
    @establishment = Establishment.find(params[:establishment_id])
  end

  def set_tracking
    @establishment_tracking = EstablishmentTracking.find(params[:id])
    authorize @establishment_tracking
  end

  def set_system_labels
    @system_labels = TrackingLabel.where(system: true).pluck(:name, :id)
  end

  def update_state
    desired_state = params[:establishment_tracking][:state]

    case desired_state
    when 'completed'
      @establishment_tracking.complete! if @establishment_tracking.may_complete?
    when 'under_surveillance'
      @establishment_tracking.start_surveillance! if @establishment_tracking.may_start_surveillance?
    when 'in_progress'
      @establishment_tracking.resume! if @establishment_tracking.may_resume?
    else
      false
    end
  end

  def tracking_params
    params.require(:establishment_tracking).permit(:contact, :state, :criticality_id, :size_id, tracking_label_ids: [], action_ids: [], sector_ids: [], participant_ids: [], referent_ids: [])
  end

  def contributor_params
    params.require(:establishment_tracking).permit(participant_ids: [], referent_ids: [])
  end

  def generate_excel(establishment_trackings, filters)
    EstablishmentTrackingExcelGenerator.new(establishment_trackings, filters, current_user).generate
  end

  def handle_filters(params)
    if params[:clear_filters]
      session[:establishment_tracking_filters] = nil
      {}
    elsif params[:q].present?
      session[:establishment_tracking_filters] = params[:q]
      params[:q]
    else
      session[:establishment_tracking_filters] || {}
    end
  end

  def export_establishment_trackings(establishment_trackings, query)
    all_establishment_trackings = establishment_trackings.includes(:establishment, :referents)
    response.headers['Cache-Control'] = 'no-store'
    send_data generate_excel(all_establishment_trackings, query),
              filename: "accompagnements.xlsx",
              type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
              disposition: 'attachment'
  end
end