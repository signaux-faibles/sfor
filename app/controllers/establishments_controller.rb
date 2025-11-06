class EstablishmentsController < ApplicationController # rubocop:disable Metrics/ClassLength
  before_action :set_establishment, only: %i[show data_effectif_ap_widget establishment_trackings_list_widget]

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

  def data_urssaf_widget # rubocop:disable Metrics/MethodLength
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
      I18n.l(d, format: "%B %Y", locale: :fr).capitalize
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
      54_478,
      56_548,
      58_645,
      60_639,
      62_570,
      64_281,
      67_293,
      67_293,
      68_576,
      68_576,
      69_708,
      69_708,
      69_708,
      69_708,
      68_868.765625,
      67_736.765625,
      67_736.765625,
      69_438.765625,
      69_438.765625,
      69_438.765625,
      68_526.765625,
      68_526.765625,
      66_823.765625,
      64_823.76171875
    ]

    @parts_salariales = [
      36_898,
      38_358,
      39_930,
      40_987,
      41_872,
      43_670,
      45_168,
      45_168,
      45_703,
      45_703,
      46_830,
      46_830,
      46_830,
      46_830,
      46_830,
      45_703,
      45_703,
      46_365,
      46_365,
      46_365,
      47_252,
      47_252,
      46_590,
      46_590
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

    ## @TODO : remove this -> test data state.
    # @cotisations = []
    # @parts_patronales = []
    # @parts_salariales = []
    # @montant_echeancier = []
    # @error = nil;
    # @error = 301;

    @dataset_names = [
      "Cotisations appelées",
      "Dette restante (part salariale)",
      "Dette restante (part patronale)",
      "Montant de l'échéancier du délai de paiement"
    ]

    render partial: "data_urssaf_widget"
  end

  def data_effectif_ap_widget
    start_date = 24.months.ago.beginning_of_month.to_date
    periodes, @formatted_periodes = generate_formatted_periods(start_date)

    effectifs_data = fetch_effectifs_data(start_date)
    ap_data = fetch_ap_data(start_date)

    @effectifs = map_periodes_to_effectifs(periodes, effectifs_data)
    @consommation_ap = map_periodes_to_consommation(periodes, ap_data)
    @autorisation_ap = map_periodes_to_autorisation(periodes, ap_data)
    @dataset_names = effectif_ap_dataset_names

    render partial: "data_effectif_ap_widget"
  end

  def establishment_trackings_list_widget
    @establishment_trackings = EstablishmentTracking.where(establishment: @establishment)

    @in_progress_trackings = @establishment_trackings.in_progress
    @completed_trackings = @establishment_trackings.completed

    # @in_progress_trackings = []
    # @completed_trackings = []

    render partial: "establishment_trackings_list_widget"
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

  def generate_formatted_periods(start_date) # rubocop:disable Metrics/MethodLength
    end_date = Date.current.end_of_month
    current_date = start_date
    periodes = []

    while current_date <= end_date
      periodes << current_date.beginning_of_month.iso8601
      current_date = current_date.next_month
    end

    formatted = periodes.map do |date_str|
      d = Date.parse(date_str)
      I18n.l(d, format: "%B %Y", locale: :fr).capitalize
    end

    [periodes, formatted]
  end

  def fetch_effectifs_data(start_date)
    OsfEffectif
      .where(siret: @establishment.siret)
      .where(periode: start_date..)
      .order(:periode)
      .pluck(:periode, :effectif)
      .to_h
  end

  def fetch_ap_data(start_date)
    OsfAp
      .where(siret: @establishment.siret)
      .where(periode: start_date..)
      .order(:periode)
      .pluck(:periode, :etp_consomme, :etp_autorise)
      .index_by { |row| row[0] }
  end

  def map_periodes_to_effectifs(periodes, effectifs_data)
    periodes.map do |periode_str|
      periode_date = Date.parse(periode_str)
      effectifs_data[periode_date] || 0
    end
  end

  def map_periodes_to_consommation(periodes, ap_data)
    periodes.map do |periode_str|
      periode_date = Date.parse(periode_str)
      ap_record = ap_data[periode_date]
      ap_record ? (ap_record[1] || 0).round : 0
    end
  end

  def map_periodes_to_autorisation(periodes, ap_data)
    periodes.map do |periode_str|
      periode_date = Date.parse(periode_str)
      ap_record = ap_data[periode_date]
      ap_record ? (ap_record[2] || 0).round : 0
    end
  end

  def effectif_ap_dataset_names
    [
      "Effectifs (salariés)",
      "Consommation activité partielle (ETP)",
      "Autorisation activité partielle (salariés)"
    ]
  end
end
