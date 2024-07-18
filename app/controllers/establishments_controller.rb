class EstablishmentsController < ApplicationController
  before_action :set_establishment, only: %i[show]

  def index
    @q = Establishment.ransack(params[:q])
    @establishments = @q.result(distinct: true)
  end

  def show
    @trackings = @establishment.establishment_trackings.includes(:creator)
  end

  private

  def set_establishment
    @establishment = Establishment.find(params[:id])
  end
end