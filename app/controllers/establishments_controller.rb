class EstablishmentsController < ApplicationController
  before_action :set_establishment, only: %i[show]

  def index
    @establishments = Establishment.all
  end

  def show
  end

  private

  def set_establishment
    @establishment = Establishment.find(params[:id])
  end
end