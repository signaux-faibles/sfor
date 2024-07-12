class EstablishmentsController < ApplicationController
  before_action :set_establishment, only: %i[show]

  def index
    if params[:campaign_id].present?
      @establishments = Establishment.by_campaign(params[:campaign_id])
    else
      @establishments = Establishment.all
    end
  end

  def show
    @trackings = @establishment.establishment_trackings.includes(:creator)
  end

  private

  def set_establishment
    @establishment = Establishment.find(params[:id])
  end
end