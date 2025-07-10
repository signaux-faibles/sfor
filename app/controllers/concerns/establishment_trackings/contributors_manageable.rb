# frozen_string_literal: true

module EstablishmentTrackings::ContributorsManageable # rubocop:disable Metrics/ModuleLength
  extend ActiveSupport::Concern

  included do
    before_action :set_tracking, only: %i[manage_contributors update_contributors remove_referent remove_participant]
  end

  def manage_contributors
    authorize @establishment_tracking
  end

  def update_contributors
    authorize @establishment_tracking, :manage_contributors?
    @establishment_tracking.modifier = current_user

    old_contributors = capture_current_contributors

    if @establishment_tracking.update(contributor_params)
      handle_successful_update(old_contributors)
    else
      handle_failed_update
    end
  end

  def remove_referent # rubocop:disable Metrics/MethodLength
    authorize @establishment_tracking, :manage_contributors?
    @establishment_tracking.modifier = current_user

    user = User.find(params[:user_id])
    @tracking_referent = @establishment_tracking.tracking_referents.find_by(user: user)

    if @tracking_referent&.destroy
      # Create snapshot for referent removal
      create_referents_snapshot_if_changed([user], [])

      respond_to do |format|
        format.turbo_stream
      end
    else
      render_error_turbo_stream(tracking_referent_error_message)
    end
  end

  def remove_participant # rubocop:disable Metrics/MethodLength
    authorize @establishment_tracking, :manage_contributors?
    @establishment_tracking.modifier = current_user

    user = User.find(params[:user_id])
    @tracking_participant = @establishment_tracking.tracking_participants.find_by(user: user)

    if @tracking_participant&.destroy
      # Create snapshot for participant removal
      create_participants_snapshot_if_changed([user], [])

      respond_to do |format|
        format.turbo_stream
      end
    else
      render_error_turbo_stream(tracking_participant_error_message)
    end
  end

  private

  def capture_current_contributors
    {
      referents: @establishment_tracking.referents.to_a,
      participants: @establishment_tracking.participants.to_a
    }
  end

  def handle_successful_update(old_contributors)
    new_referents = @establishment_tracking.referents.reload.to_a
    new_participants = @establishment_tracking.participants.reload.to_a

    create_referents_snapshot_if_changed(old_contributors[:referents], new_referents)
    create_participants_snapshot_if_changed(old_contributors[:participants], new_participants)

    flash[:success] = t("establishments.tracking.contributors.update.success")
    redirect_to [@establishment, @establishment_tracking]
  end

  def handle_failed_update
    @establishment_tracking.reload
    render :manage_contributors, status: :unprocessable_entity
  end

  def contributor_params # rubocop:disable Metrics/MethodLength
    establishment_tracking_params = params.require(:establishment_tracking).permit(
      referent_ids: [],
      discarded_referent_ids: [],
      participant_ids: [],
      discarded_participant_ids: []
    )

    {
      referent_ids: combine_ids(establishment_tracking_params[:referent_ids],
                                establishment_tracking_params[:discarded_referent_ids]),
      participant_ids: combine_ids(establishment_tracking_params[:participant_ids],
                                   establishment_tracking_params[:discarded_participant_ids])
    }
  end

  def combine_ids(active_ids, discarded_ids)
    (active_ids || []).compact_blank + (discarded_ids || []).compact_blank
  end

  def tracking_referent_error_message
    return t("establishments.tracking.contributors.remove_referent.error") unless @tracking_referent

    @tracking_referent.errors.full_messages.first || t("establishments.tracking.contributors.remove_referent.error")
  end

  def tracking_participant_error_message
    return t("establishments.tracking.contributors.remove_participant.error") unless @tracking_participant

    @tracking_participant.errors.full_messages.first || t("establishments.tracking.contributors.remove_participant.error") # rubocop:disable Layout/LineLength
  end

  def render_error_turbo_stream(message)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("error_explanation", partial: "shared/error",
                                                                       locals: { message: message })
      end
    end
  end

  def create_referents_snapshot_if_changed(old_referents, new_referents)
    create_contributors_snapshot_if_changed(old_referents, new_referents, "referents_change", "referent")
  end

  def create_participants_snapshot_if_changed(old_participants, new_participants)
    create_contributors_snapshot_if_changed(old_participants, new_participants, "participants_change", "participant")
  end

  def create_contributors_snapshot_if_changed(old_users, new_users, event_type, role_name) # rubocop:disable Metrics/MethodLength
    return if old_users.map(&:id).sort == new_users.map(&:id).sort

    added = new_users - old_users
    removed = old_users - new_users
    return if added.empty? && removed.empty?

    description, changes_summary = build_change_data(added, removed, role_name)

    @establishment_tracking.snapshot_service.create_event_and_snapshot!(
      event_type: event_type,
      triggered_by_user: current_user,
      description: "#{description} for #{@establishment_tracking.establishment.raison_sociale}",
      changes_summary: changes_summary
    )
  end

  def build_change_data(added, removed, role_name) # rubocop:disable Metrics/MethodLength
    description_parts = []
    changes_summary = {}

    if added.any?
      description_parts << "Added #{role_name}(s): #{added.map(&:email).join(', ')}"
      changes_summary[:added] = user_summary(added)
    end

    if removed.any?
      description_parts << "Removed #{role_name}(s): #{removed.map(&:email).join(', ')}"
      changes_summary[:removed] = user_summary(removed)
    end

    [description_parts.join("; "), changes_summary]
  end

  def user_summary(users)
    users.map { |user| { id: user.id, email: user.email, name: user.full_name } }
  end
end
