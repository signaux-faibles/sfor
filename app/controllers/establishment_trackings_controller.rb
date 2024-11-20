class EstablishmentTrackingsController < ApplicationController
  before_action :set_establishment, except: %i[new_by_siret index]
  before_action :set_tracking, only: %i[show destroy edit update]

  def index
    @q = policy_scope(EstablishmentTracking).ransack(params[:q])

    if params.dig(:q, :my_tracking) == '1'
      @establishment_trackings = @q.result.with_user_as_referent_or_participant(current_user)
    else
      @establishment_trackings = @q.result
    end

    @paginated_establishment_trackings = @establishment_trackings.includes(:establishment, :referents, :tracking_labels).page(params[:page]).per(5)

    respond_to do |format|
      format.html
      format.xlsx do
        all_establishment_trackings = @establishment_trackings.includes(:establishment, :referents, :tracking_labels)

        response.headers['Cache-Control'] = 'no-store'
        send_data generate_excel(all_establishment_trackings),
                  filename: "accompagnements.xlsx",
                  type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                  disposition: 'attachment'
      end
    end
  end
  def show
    @user_network = current_user.network

    @network_summaries = @establishment_tracking.summaries
                                                .where(network: @user_network)
                                                .select { |summary| authorize summary }

    @codefi_summaries = @establishment_tracking.summaries
                                               .where(network_id: nil)
                                               .select { |summary| authorize summary }

    @network_comments = @establishment_tracking.comments
                                               .where(network: @user_network)
                                               .order(created_at: :desc)
                                               .select { |comment| authorize comment }

    @codefi_comments = @establishment_tracking.comments
                                              .where(network_id: nil)
                                              .order(created_at: :desc)
                                              .select { |comment| authorize comment }

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

  def generate_excel(establishment_trackings)
    package = Axlsx::Package.new
    workbook = package.workbook

    workbook.add_worksheet(name: "Accompagnements") do |sheet|
      sheet.add_row ["Raison sociale", "Siret", "Département", "Participants", "Assignés", "Date de début", "Statut", "Synthèse"]


      establishment_trackings.each do |tracking|
        summary = tracking.summaries.find_by(network: @user_network)
        sheet.add_row [
                        tracking.establishment.raison_sociale,
                        tracking.establishment.siret,
                        tracking.establishment&.department.name,
                        tracking.participants.map(&:full_name).join(', '),
                        tracking.referents.map(&:full_name).join(', '),
                        tracking.start_date.present? ? tracking.start_date.strftime('%d/%m/%Y') : '-',
                        tracking.aasm.human_state,
                        summary&.content || 'Aucune synthèse rédigée'
                      ]
      end
    end

    package.to_stream.read
  end
end