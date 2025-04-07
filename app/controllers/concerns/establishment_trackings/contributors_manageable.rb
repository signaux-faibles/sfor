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

  def contributor_params
    params.require(:establishment_tracking).permit(participant_ids: [], referent_ids: [])
  end
end
