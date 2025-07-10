# frozen_string_literal: true

module EstablishmentTrackings::ContributorsManageable
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

    if @establishment_tracking.update(contributor_params)
      flash[:success] = t("establishments.tracking.contributors.update.success")
      redirect_to [@establishment, @establishment_tracking]
    else
      @establishment_tracking.reload
      render :manage_contributors, status: :unprocessable_entity
    end
  end

  def remove_referent # rubocop:disable Metrics/MethodLength
    authorize @establishment_tracking, :manage_contributors?
    @establishment_tracking.modifier = current_user

    user = User.find(params[:user_id])
    @tracking_referent = @establishment_tracking.tracking_referents.find_by(user: user)

    if @tracking_referent&.destroy
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
      respond_to do |format|
        format.turbo_stream
      end
    else
      render_error_turbo_stream(tracking_participant_error_message)
    end
  end

  private

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
end
