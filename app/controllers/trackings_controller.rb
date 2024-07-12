class TrackingsController < ApplicationController
  before_action :set_establishment, only: %i[new create]
  before_action :set_tracking, only: %i[show destroy]

  def new
    @tracking = @establishment.establishment_trackings.new
  end

  def create
    @tracking = @establishment.establishment_trackings.new(tracking_params)
    @tracking.creator = current_user

    @tracking.participant_ids << current_user.id unless @tracking.participant_ids.include?(current_user.id)

    if @tracking.save
      redirect_to @establishment, notice: 'Le suivi a été créé avec succès.'
    else
      render :new
    end
  end

  def show
  end

  def destroy
    @establishment = @tracking.establishment
    @tracking.destroy
    redirect_to @establishment, notice: 'Le suivi a été supprimé avec succès.'
  end

  private

  def set_establishment
    @establishment = Establishment.find(params[:establishment_id])
  end

  def set_tracking
    @tracking = EstablishmentTracking.find(params[:id])
  end

  def tracking_params
    params.require(:establishment_tracking).permit(:start_date, :end_date, :status, participant_ids: [])
  end
end