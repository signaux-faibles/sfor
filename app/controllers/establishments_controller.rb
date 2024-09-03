class EstablishmentsController < ApplicationController
  before_action :set_establishment, only: %i[show]

  def index
    @q = Establishment.ransack(params[:q])
    @establishments = @q.result(distinct: true)
  end

  def show
    @trackings = policy_scope(@establishment.establishment_trackings).includes(:creator)
  end
  def new
    @establishment = Establishment.find_by(siret: params[:establishment_siret])
    if @establishment
      @establishment_tracking = EstablishmentTracking.new(establishment: @establishment)
      # Autres initialisations si nécessaire
    else
      redirect_to some_path, alert: 'Establishment not found'
    end
  end

  private

  def set_establishment
    @establishment = Establishment.find(params[:id])
  end
end