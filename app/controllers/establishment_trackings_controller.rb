class EstablishmentTrackingsController < ApplicationController
  before_action :set_establishment, except: %i[new_by_siret index]
  before_action :set_tracking, only: %i[show destroy edit update]

  def index
    @q = policy_scope(EstablishmentTracking).ransack(params[:q])

    if params.dig(:q, :my_tracking) == '1'
      puts "ON prend bien que les miens"
      @establishment_trackings = @q.result.with_user_as_referent_or_participant(current_user)
    else
      puts "On prend tout"
      @establishment_trackings = @q.result
    end

    @establishment_trackings = @establishment_trackings.includes(:establishment, :referents, :tracking_labels).page(params[:page]).per(5)
  end
  def show
    @user_segment = current_user.segment

    # Filtrage des summaries par segment avec Pundit
    @segment_summaries = @establishment_tracking.summaries
                                                .where(segment: @user_segment)
                                                .select { |summary| authorize summary }

    # Filtrage des summaries CODEFI avec Pundit
    @codefi_summaries = @establishment_tracking.summaries
                                               .where(segment_id: nil)
                                               .select { |summary| authorize summary }

    # Filtrage des comments par segment avec Pundit
    @segment_comments = @establishment_tracking.comments
                                               .where(segment: @user_segment)
                                               .order(created_at: :desc)
                                               .select { |comment| authorize comment }

    # Filtrage des comments CODEFI avec Pundit
    @codefi_comments = @establishment_tracking.comments
                                              .where(segment_id: nil)
                                              .order(created_at: :desc)
                                              .select { |comment| authorize comment }

    # Gestion des erreurs d'autorisation
  rescue Pundit::NotAuthorizedError
    flash[:alert] = "Vous n'êtes pas autorisé à voir certains éléments."
    redirect_back(fallback_location: root_path)
  end

  def new
    @establishment_tracking = @establishment.establishment_trackings.new
    @establishment_tracking.referents << current_user
  end

  def new_by_siret
    # TODO. ce code a vocation à disparaître. Dans le futur on veut avoir la base de SIREN/SIRET dans la bdd de l'appli rails
    @establishment = Establishment.find_by(siret: params[:siret])

    if @establishment
      redirect_to new_establishment_establishment_tracking_path(@establishment)
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
        redirect_to new_establishment_establishment_tracking_path(@establishment), notice: 'Établissement créé avec succès.'
      else
        redirect_to root_path, alert: "Impossible de créer l'établissement: #{@establishment.errors.full_messages.join(', ')}"
      end
    end
  end

  def edit
  end

  def update
    if update_state && @establishment_tracking.update(tracking_params)
      flash[:success] = 'L\'accompagnement a été mis à jour avec succès.'
      redirect_to [@establishment, @establishment_tracking]
    else
      render :edit, status: :unprocessable_entity
    end
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

  private

  def set_establishment
    @establishment = Establishment.find(params[:establishment_id])
  end

  def set_tracking
    @establishment_tracking = EstablishmentTracking.find(params[:id])
    authorize @establishment_tracking
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
    params.require(:establishment_tracking).permit(:state, participant_ids: [], referent_ids: [], tracking_label_ids: [], action_ids: [])
  end
end