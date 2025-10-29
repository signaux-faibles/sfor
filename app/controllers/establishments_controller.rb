class EstablishmentsController < ApplicationController
  before_action :set_establishment, only: %i[show]

  def index
    @q = Establishment.ransack(params[:q])
    @establishments = @q.result(distinct: true)
  end

  def show
    load_trackings
  end

  def insee_widget
    @establishment = Establishment.find_by!(siret: params[:siret])
    fetch_insee_data
    render partial: "insee_widget"
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

  def fetch_insee_data # rubocop:disable Metrics/AbcSize
    return if @establishment.siret.blank?

    service = Api::InseeApiService.new
    @insee_data = service.fetch_establishment_by_siret(@establishment.siret)

    siren = @insee_data&.dig("data", "unite_legale", "siren")
    @company_insee_data = service.fetch_unite_legale_by_siren(siren) if siren.present?

    date_fermeture = @insee_data&.dig("data", "date_fermeture")
    @date_fermeture_formatted = Time.at(date_fermeture).to_date.strftime("%d/%m/%Y") if date_fermeture.present?
  rescue StandardError => e
    Rails.logger.error "Erreur lors de la récupération des données INSEE: #{e.message}"
    @insee_data = nil
  end
end
