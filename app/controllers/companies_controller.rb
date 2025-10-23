class CompaniesController < ApplicationController
  before_action :set_company, only: %i[show insee_widget financial_widget establishments_widget]

  def index
    initialize_search_params
    load_reference_data
    @companies = @q.result(distinct: true)
  end

  def show
    @establishments = @company.establishments_ordered
    # No longer fetch data here - will be loaded by Turbo Frames
  end

  def insee_widget
    fetch_insee_data
    render partial: "insee_widget"
  end

  def data_urssaf_widget
    @company = Company.find_by!(siren: params[:siren])

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

  def financial_widget
    fetch_financial_data
    render partial: "financial_widget"
  end

  def establishments_widget
    fetch_establishments_data
    render partial: "establishments_widget"
  end

  private

  def initialize_search_params
    @q = Company.ransack(params[:q])
    @lists = List.all
    set_default_list
  end

  def set_default_list
    @latest_list = @lists.order(created_at: :desc).first
    params[:q] ||= {}
    if params[:q][:lists_id_eq].blank? && @latest_list
      params[:q][:lists_id_eq] = @latest_list.id
      @q = Company.ransack(params[:q])
    end
  end

  def load_reference_data
    @campaigns = Campaign.all
    @departments = Department.all
    @activity_sectors = ActivitySector.all
    @lists = List.all
  end

  def set_company
    @company = Company.find_by!(siren: params[:siren])
  end

  def fetch_insee_data
    return if @company.siren.blank?

    service = Api::InseeApiService.new
    @insee_data = service.fetch_unite_legale_by_siren_siege(@company.siren)

    date_fermeture = @insee_data&.dig("data", "date_fermeture")
    if date_fermeture.present?
      @date_fermeture_formatted = Time.at(date_fermeture).to_date.strftime('%d/%m/%Y')
    end
  rescue StandardError => e
    Rails.logger.error "Erreur lors de la récupération des données INSEE: #{e.message}"
    @insee_data = nil
  end

  def fetch_financial_data
    return if @company.siren.blank?

    service = Api::BanqueDeFranceApiService.new(siren: @company.siren)
    @financial_data = service.fetch_bilans
  rescue StandardError => e
    Rails.logger.error "Erreur lors de la récupération des données financières: #{e.message}"
    @financial_data = nil
  end

  def fetch_establishments_data # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    return if @company.siren.blank?

    # Récupérer les établissements de la base de données
    establishments = @company.establishments_ordered

    # Enrichir chaque établissement avec les données INSEE
    @enriched_establishments = []

    establishments.each do |establishment|
      service = Api::InseeApiService.new(siret: establishment.siret, siren: nil)
      api_data = service.fetch_establishment_by_siret(establishment.siret)

      # Combiner les données Rails avec les données API
      enriched_establishment = {
        rails_data: establishment,
        insee_data: api_data&.dig("data"),
        has_api_data: api_data&.dig("data").present?
      }

      @enriched_establishments << enriched_establishment
    rescue StandardError => e
      Rails.logger.error "Erreur lors de la récupération des données INSEE pour #{establishment.siret}: #{e.message}"

      # Ajouter l'établissement même sans données API
      @enriched_establishments << {
        rails_data: establishment,
        insee_data: nil,
        has_api_data: false
      }
    end
  rescue StandardError => e
    Rails.logger.error "Erreur lors de la récupération des établissements: #{e.message}"
    @enriched_establishments = []
  end
end
