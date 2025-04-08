class EstablishmentTrackingsController < ApplicationController # rubocop:disable Metrics/ClassLength
  include EstablishmentTrackings::Filterable
  include EstablishmentTrackings::Exportable
  include EstablishmentTrackings::Creatable
  include EstablishmentTrackings::StateManageable
  include EstablishmentTrackings::Loadable
  include EstablishmentTrackings::ContributorsManageable

  before_action :set_paper_trail_whodunnit

  before_action :set_establishment, except: %i[new_by_siret index]
  before_action :set_tracking,
                only: %i[show destroy edit update manage_contributors update_contributors remove_referent
                         remove_participant]
  before_action :set_system_labels, only: %i[new new_by_siret edit update create]

  def index
    params[:q] = handle_filters(params)
    clean_params = handle_view_params(params)
    @establishment_trackings = apply_filters(determine_base_scope, clean_params)
    @paginated_establishment_trackings = paginate_trackings(@establishment_trackings)

    respond_to do |format|
      format.html
      format.xlsx do
        export_establishment_trackings(@establishment_trackings, @q)
      end
    end
  end

  def show
    user_network_ids = current_user.networks.pluck(:id)
    load_summaries(user_network_ids)
    load_comments(user_network_ids)
    load_related_trackings
  end

  def new
    @establishment_tracking = @establishment.establishment_trackings.new
    @establishment_tracking.referents << current_user
  end

  def new_by_siret
    @establishment = Establishment.find_by(siret: params[:siret])

    if @establishment
      handle_existing_establishment
    else
      create_new_establishment
    end
  end

  def edit; end

  def create
    @establishment_tracking = @establishment.establishment_trackings.new(tracking_params)
    @establishment_tracking.creator = current_user
    @establishment_tracking.start_date ||= Time.zone.today

    if @establishment_tracking.save
      flash[:success] = t("establishments.tracking.create.success")
      redirect_to @establishment
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    ActiveRecord::Base.transaction do
      if update_state && @establishment_tracking.update(prepare_label_params(tracking_params))
        flash[:success] = t("establishments.tracking.update.success")
        redirect_to [@establishment, @establishment_tracking]
      else
        render :edit, status: :unprocessable_entity
      end
    end
  end

  def destroy
    @establishment = @establishment_tracking.establishment
    @establishment_tracking.destroy
    flash[:success] = t("establishments.tracking.destroy.success")
    redirect_to @establishment
  end

  def manage_contributors
    authorize @establishment_tracking
  end

  def update_contributors
    authorize @establishment_tracking, :manage_contributors?

    if @establishment_tracking.update(contributor_params)
      flash[:success] = t("establishments.tracking.contributors.update.success")
      redirect_to [@establishment, @establishment_tracking]
    else
      flash[:error] = t("establishments.tracking.contributors.update.error")
      render :manage_contributors, status: :unprocessable_entity
    end
  end

  def remove_referent
    authorize @establishment_tracking, :manage_contributors?
    user = User.find(params[:user_id])

    if @establishment_tracking.tracking_referents.find_by(user: user)&.destroy
      flash[:success] = t("establishments.tracking.contributors.remove_referent.success")
    else
      flash[:error] = t("establishments.tracking.contributors.remove_referent.error")
    end

    redirect_to [@establishment, @establishment_tracking]
  end

  def remove_participant
    authorize @establishment_tracking, :manage_contributors?
    user = User.find(params[:user_id])

    if @establishment_tracking.tracking_participants.find_by(user: user)&.destroy
      flash[:success] = t("establishments.tracking.contributors.remove_participant.success")
    else
      flash[:error] = t("establishments.tracking.contributors.remove_participant.error")
    end

    redirect_to [@establishment, @establishment_tracking]
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

  def tracking_params
    params.require(:establishment_tracking).permit(
      :state, :criticality_id, :size_id,
      tracking_label_ids: [], user_action_ids: [], sector_ids: [],
      participant_ids: [], referent_ids: [], difficulty_ids: [],
      codefi_redirect_ids: [], supporting_service_ids: []
    )
  end

  def contributor_params
    params.require(:establishment_tracking).permit(participant_ids: [], referent_ids: [])
  end
end
