class EstablishmentsController < ApplicationController
  before_action :set_establishment, only: %i[show]

  def index
    @q = Establishment.ransack(params[:q])
    @establishments = @q.result(distinct: true)
  end

  def show
    load_trackings
  end

  def new
    @establishment = Establishment.find_by(siret: params[:establishment_siret])
    if @establishment
      @establishment_tracking = EstablishmentTracking.new(establishment: @establishment)
      # Autres initialisations si nécessaire
    else
      redirect_to some_path, alert: t("establishments.not_found")
    end
  end

  private

  def set_establishment
    @establishment = Establishment.find_by!(siret: params[:siret])
  end

  def load_trackings
    @in_progress_trackings = load_trackings_by_state(:in_progress)
    @completed_trackings = load_trackings_by_state(:completed)
    @under_surveillance_trackings = load_trackings_by_state(:under_surveillance)
  end

  def load_trackings_by_state(state)
    policy_scope(@establishment.establishment_trackings)
      .includes(:creator, :criticality, :referents)
      .send(state)
      .order(start_date: :asc)
  end
end
