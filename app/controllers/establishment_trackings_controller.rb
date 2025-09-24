class EstablishmentTrackingsController < ApplicationController # rubocop:disable Metrics/ClassLength
  include EstablishmentTrackings::Filterable
  include EstablishmentTrackings::Exportable
  include EstablishmentTrackings::Creatable
  include EstablishmentTrackings::StateManageable
  include EstablishmentTrackings::Loadable
  include EstablishmentTrackings::ContributorsManageable
  include EstablishmentTrackings::SupportingServicesTrackable

  before_action :set_paper_trail_whodunnit

  before_action :set_establishment, except: %i[new_by_siret index]
  before_action :set_tracking, # rubocop:disable Rails/LexicallyScopedActionFilter
                only: %i[show destroy edit update manage_contributors update_contributors remove_referent
                         remove_participant confirm complete]
  before_action :set_system_labels, only: %i[index new new_by_siret edit update create confirm]

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

  def confirm; end

  def create # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    @establishment_tracking = @establishment.establishment_trackings.new(tracking_params)
    @establishment_tracking.creator = current_user
    @establishment_tracking.modifier = current_user
    @establishment_tracking.start_date ||= Time.zone.today

    authorize @establishment_tracking

    if @establishment_tracking.save
      flash[:success] = t("establishments.tracking.create.success")
      redirect_to [@establishment, @establishment_tracking]
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @establishment_tracking.modifier = current_user

    # Capture old supporting services before update
    old_supporting_services = @establishment_tracking.supporting_services.to_a

    ActiveRecord::Base.transaction do
      if tracking_params[:state] == "completed"
        handle_completed_state_update(old_supporting_services)
      else
        handle_regular_update(old_supporting_services)
      end
    end
  end

  def destroy
    @establishment = @establishment_tracking.establishment
    @establishment_tracking.destroy
    flash[:success] = t("establishments.tracking.destroy.success")
    redirect_to @establishment
  end

  def complete
    @establishment_tracking.modifier = current_user

    if @establishment_tracking.update(state: "completed", end_date: Time.zone.today)
      flash[:success] = t("establishments.tracking.complete.success", raison_sociale: @establishment.raison_sociale)
      redirect_to [@establishment, @establishment_tracking]
    else
      render :confirm, status: :unprocessable_entity
    end
  end

  private

  def set_establishment
    @establishment = Establishment.find_by!(siret: params[:establishment_siret])
  end

  def set_tracking
    @establishment_tracking = EstablishmentTracking.includes(
      tracking_referents: { user: :entity },
      tracking_participants: { user: :entity }
    ).find(params[:id])
    authorize @establishment_tracking
  end

  def set_system_labels
    @system_labels = TrackingLabel.kept.where(system: true).pluck(:name, :id)
  end

  def tracking_params
    params.require(:establishment_tracking).permit(
      :state, :criticality_id,
      tracking_label_ids: [], user_action_ids: [], sector_ids: [],
      participant_ids: [], referent_ids: [], difficulty_ids: [],
      codefi_redirect_ids: [], supporting_service_ids: []
    )
  end

  def handle_completed_state_update(old_supporting_services) # rubocop:disable Metrics/MethodLength
    if @establishment_tracking.completed? && @establishment_tracking.update(prepare_label_params(tracking_params))
      track_supporting_services_changes_if_any(old_supporting_services)
      redirect_to(
        [@establishment, @establishment_tracking],
        success: t("establishments.tracking.update.success")
      )
    elsif @establishment_tracking.update(prepare_label_params(tracking_params.except(:state)))
      track_supporting_services_changes_if_any(old_supporting_services)
      redirect_to(
        confirm_establishment_establishment_tracking_path(@establishment, @establishment_tracking)
      )
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def handle_regular_update(old_supporting_services)
    if @establishment_tracking.update(prepare_label_params(tracking_params))
      track_supporting_services_changes_if_any(old_supporting_services)
      flash[:success] = t("establishments.tracking.update.success")
      redirect_to [@establishment, @establishment_tracking]
    else
      render :edit, status: :unprocessable_entity
    end
  end
end
