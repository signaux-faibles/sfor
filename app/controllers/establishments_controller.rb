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

  def data_urssaf_widget
    periodes = [
      "2023-09-01T00:00:00Z",
      "2023-10-01T00:00:00Z",
      "2023-11-01T00:00:00Z",
      "2023-12-01T00:00:00Z",
      "2024-01-01T00:00:00Z",
      "2024-02-01T00:00:00Z",
      "2024-03-01T00:00:00Z",
      "2024-04-01T00:00:00Z",
      "2024-05-01T00:00:00Z",
      "2024-06-01T00:00:00Z",
      "2024-07-01T00:00:00Z",
      "2024-08-01T00:00:00Z",
      "2024-09-01T00:00:00Z",
      "2024-10-01T00:00:00Z",
      "2024-11-01T00:00:00Z",
      "2024-12-01T00:00:00Z",
      "2025-01-01T00:00:00Z",
      "2025-02-01T00:00:00Z",
      "2025-03-01T00:00:00Z",
      "2025-04-01T00:00:00Z",
      "2025-05-01T00:00:00Z",
      "2025-06-01T00:00:00Z",
      "2025-07-01T00:00:00Z",
      "2025-08-01T00:00:00Z"
    ]

    @formatted_periodes = periodes.map do |date|
      d = Date.parse(date)
      I18n.l(d, format: '%B %Y', locale: :fr).capitalize
    end

    @cotisations = [
      5291.58349609375,
      5056.58349609375,
      5749.58349609375,
      4647.58349609375,
      2103,
      1818,
      1341,
      2259,
      2378,
      2149,
      2935,
      2948,
      2921,
      3608,
      2365,
      2718,
      2946,
      2835,
      3031,
      3733,
      5440,
      4576,
      3873
    ]

    @parts_patronales = [
      54478,
      56548,
      58645,
      60639,
      62570,
      64281,
      67293,
      67293,
      68576,
      68576,
      69708,
      69708,
      69708,
      69708,
      68868.765625,
      67736.765625,
      67736.765625,
      69438.765625,
      69438.765625,
      69438.765625,
      68526.765625,
      68526.765625,
      66823.765625,
      64823.76171875
    ]

    @parts_salariales = [
      36898,
      38358,
      39930,
      40987,
      41872,
      43670,
      45168,
      45168,
      45703,
      45703,
      46830,
      46830,
      46830,
      46830,
      46830,
      45703,
      45703,
      46365,
      46365,
      46365,
      47252,
      47252,
      46590,
      46590
    ]

    @montant_echeancier = [
      4523,
      3891,
      2456,
      4102,
      3287,
      4789,
      2134,
      3654,
      4421,
      2987,
      3156,
      4678,
      2543,
      3912,
      4234,
      2876,
      3534,
      4567,
      2298,
      3789,
      4345,
      2654,
      3423,
      4891
    ]

    @dataset_names = [
      "Cotisations appelées",
      "Dette restante (part salariale)",
      "Dette restante (part patronale)",
      "Montant de l'échéancier du délai de paiement"
    ]

    render partial: "data_urssaf_widget"
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

  def fetch_insee_data
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
