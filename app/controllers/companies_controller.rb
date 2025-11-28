class CompaniesController < ApplicationController # rubocop:disable Metrics/ClassLength
  before_action :set_company, only: %i[show insee_widget financial_widget establishments_widget detection_widget]

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

  def detection_widget
    fetch_alert_history
    render partial: "detection_widget"
  end

  def data_urssaf_widget # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    @company = Company.find_by!(siren: params[:siren])

    start_date = 24.months.ago.beginning_of_month.to_date
    periodes, @formatted_periodes = generate_formatted_periods(start_date)

    cotisations_data = fetch_cotisations_data(start_date)
    debits_data = fetch_debits_data(start_date)
    delais = fetch_delais_data(start_date)

    @cotisations = map_periodes_to_cotisations(periodes, cotisations_data)
    @parts_salariales = map_periodes_to_parts_salariales(periodes, debits_data)
    @parts_patronales = map_periodes_to_parts_patronales(periodes, debits_data)
    @montant_echeancier = map_periodes_to_montant_echeancier(periodes, delais)
    @dataset_names = urssaf_dataset_names

    render partial: "data_urssaf_widget"
  end

  def data_effectif_ap_widget # rubocop:disable Metrics/AbcSize
    @company = Company.find_by!(siren: params[:siren])

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

  def financial_widget
    fetch_financial_data
    render partial: "financial_widget"
  end

  def establishments_widget
    fetch_establishments_data
    render partial: "establishments_widget"
  end

  def establishment_trackings_list_widget
    @company = Company.find_by!(siren: params[:siren])
    @establishments = @company.establishments
    @establishment_trackings = EstablishmentTracking.where(establishment: @establishments)

    @in_progress_trackings = @establishment_trackings.in_progress
    @completed_trackings = @establishment_trackings.completed

    render partial: "establishment_trackings_list_widget"
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
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "Cette fiche entreprise n'existe pas dans SignauxFaibles" # rubocop:disable Rails/I18nLocaleTexts
    redirect_back(fallback_location: home_path)
  end

  def fetch_insee_data
    return if @company.siren.blank?

    service = Api::InseeApiService.new
    @insee_data = service.fetch_unite_legale_by_siren_siege(@company.siren)

    date_fermeture = @insee_data&.dig("data", "date_fermeture")
    @date_fermeture_formatted = Time.at(date_fermeture).to_date.strftime("%d/%m/%Y") if date_fermeture.present?
  rescue StandardError => e
    Rails.logger.error "Erreur lors de la récupération des données INSEE: #{e.message}"
    @insee_data = nil
  end

  def fetch_financial_data # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    return if @company.siren.blank?

    service = Api::FinancialRatiosApiService.new(siren: @company.siren)
    api_response = service.fetch_financial_ratios

    if api_response && api_response["records"].present?
      # Extract and sort records by date_cloture_exercice
      records = api_response["records"].map { |r| r["record"]["fields"] }
      records.sort_by! { |r| r["date_cloture_exercice"] || "" }

      # Extract dates and format them
      @dates = records.pluck("date_cloture_exercice").compact
      @formatted_dates = @dates.map { |d| Date.parse(d).strftime("%d/%m/%Y") }

      # Extract all available financial fields (excluding metadata fields)
      # Collect all unique keys from all records
      metadata_fields = %w[siren date_cloture_exercice type_bilan confidentiality]
      all_keys = records.flat_map(&:keys).uniq
      @financial_fields = all_keys.reject { |k| metadata_fields.include?(k) }.sort

      # Build datasets for each field
      @datasets = {}
      @dataset_names = {}
      @financial_fields.each do |field|
        values = records.map { |r| r[field] }
        @datasets[field] = values
        @dataset_names[field] = format_field_name(field)
      end

    else
      @dates = []
      @formatted_dates = []
      @financial_fields = []
      @datasets = {}
      @dataset_names = {}
    end
    @error = nil
  rescue StandardError => e
    Rails.logger.error "Erreur lors de la récupération des données financières: #{e.message}"
    @dates = []
    @formatted_dates = []
    @financial_fields = []
    @datasets = {}
    @dataset_names = {}
    @error = e.message
  end

  def format_field_name(field)
    # Convert snake_case to readable French names
    field.to_s
         .gsub("_", " ")
         .split
         .map(&:capitalize)
         .join(" ")
         .gsub("Ca", "CA")
         .gsub("Bfr", "BFR")
         .gsub("Ebe", "EBE")
         .gsub("Ebit", "EBIT")
         .gsub("Caf", "CAF")
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
        has_api_data: api_data&.dig("data").present?,
        last_effectif: OsfEffectif.last_effectif_for_siret(establishment.siret),
        active_dette_urssaf: OsfDelai.active_dette_urssaf?(establishment.siret)
      }

      @enriched_establishments << enriched_establishment
    rescue StandardError => e
      Rails.logger.error "Erreur lors de la récupération des données INSEE pour #{establishment.siret}: #{e.message}"

      # Ajouter l'établissement même sans données API
      @enriched_establishments << {
        rails_data: establishment,
        insee_data: nil,
        has_api_data: false,
        last_effectif: OsfEffectif.last_effectif_for_siret(establishment.siret),
        active_dette_urssaf: OsfDelai.active_dette_urssaf?(establishment.siret)
      }
    end
  rescue StandardError => e
    Rails.logger.error "Erreur lors de la récupération des établissements: #{e.message}"
    @enriched_establishments = []
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
    OsfEntEffectif
      .where(siren: @company.siren)
      .where(periode: start_date..)
      .order(:periode)
      .pluck(:periode, :effectif)
      .to_h
  end

  def fetch_ap_data(start_date) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
    # Aggregate AP data across all establishments of the company
    ap_records = OsfAp
                 .where(siren: @company.siren)
                 .where(periode: start_date..)
                 .order(:periode)
                 .pluck(:periode, :etp_consomme, :etp_autorise)

    # Group by periode and sum the values
    ap_data = {}
    ap_records.each do |periode, etp_consomme, etp_autorise|
      periode_date = periode
      ap_data[periode_date] = if ap_data[periode_date]
                                [
                                  periode_date,
                                  (ap_data[periode_date][1] || 0) + (etp_consomme || 0),
                                  (ap_data[periode_date][2] || 0) + (etp_autorise || 0)
                                ]
                              else
                                [periode_date, etp_consomme || 0, etp_autorise || 0]
                              end
    end

    ap_data
  end

  def map_periodes_to_effectifs(periodes, effectifs_data)
    periodes.map do |periode_str|
      periode_date = Date.parse(periode_str)
      effectifs_data[periode_date]
    end
  end

  def map_periodes_to_consommation(periodes, ap_data)
    periodes.map do |periode_str|
      periode_date = Date.parse(periode_str)
      ap_record = ap_data[periode_date]
      ap_record && ap_record[1] ? ap_record[1].round : nil
    end
  end

  def map_periodes_to_autorisation(periodes, ap_data)
    periodes.map do |periode_str|
      periode_date = Date.parse(periode_str)
      ap_record = ap_data[periode_date]
      ap_record && ap_record[2] ? ap_record[2].round : nil
    end
  end

  def effectif_ap_dataset_names
    [
      "Effectifs (salariés)",
      "Consommation activité partielle (ETP)",
      "Autorisation activité partielle (salariés)"
    ]
  end

  def fetch_cotisations_data(start_date) # rubocop:disable Metrics/MethodLength
    # Aggregate cotisations across all establishments of the company
    siret_list = @company.establishments.pluck(:siret)
    return {} if siret_list.empty?

    cotisations = OsfCotisation
                  .where(siret: siret_list)
                  .where(periode: start_date..)
                  .order(:periode)
                  .pluck(:periode, :du)

    # Group by periode (normalized to beginning of month) and sum the values
    cotisations_data = {}
    cotisations.each do |periode, du|
      # Normalize periode to beginning of month to match generated periods
      periode_normalized = periode.beginning_of_month
      cotisations_data[periode_normalized] = (cotisations_data[periode_normalized] || 0) + (du || 0)
    end

    cotisations_data
  end

  def fetch_debits_data(start_date) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    # Aggregate debits across all establishments of the company
    siret_list = @company.establishments.pluck(:siret)
    return {} if siret_list.empty?

    debits = OsfDebit
             .where(siret: siret_list)
             .where(periode: start_date..)
             .order(:periode)
             .pluck(:periode, :part_ouvriere, :part_patronale)

    # Group by periode (normalized to beginning of month) and sum the values
    debits_data = {}
    debits.each do |periode, part_ouvriere, part_patronale|
      # Normalize periode to beginning of month to match generated periods
      periode_normalized = periode.beginning_of_month
      part_ouvriere_val = part_ouvriere ? part_ouvriere.to_f : 0
      part_patronale_val = part_patronale ? part_patronale.to_f : 0

      debits_data[periode_normalized] = if debits_data[periode_normalized]
                                          [
                                            periode_normalized,
                                            debits_data[periode_normalized][1].to_f + part_ouvriere_val,
                                            debits_data[periode_normalized][2].to_f + part_patronale_val
                                          ]
                                        else
                                          [periode_normalized, part_ouvriere_val, part_patronale_val]
                                        end
    end

    debits_data
  end

  def fetch_delais_data(start_date)
    # Aggregate delais across all establishments of the company
    # Fetch all delais that might be active during the period range
    # A delai is active if: date_creation < periode < date_echeance
    # We need to fetch delais where the date range overlaps with our period range
    siret_list = @company.establishments.pluck(:siret)
    return [] if siret_list.empty?

    end_date = Date.current.end_of_month
    OsfDelai
      .where(siret: siret_list)
      .where("date_creation <= ? AND date_echeance >= ?", end_date, start_date)
      .where.not(montant_echeancier: nil)
      .where.not(date_creation: nil)
      .where.not(date_echeance: nil)
      .order(:date_creation)
  end

  def map_periodes_to_cotisations(periodes, cotisations_data)
    periodes.map do |periode_str|
      periode_date = Date.parse(periode_str)
      cotisations_data[periode_date]&.to_f
    end
  end

  def map_periodes_to_parts_salariales(periodes, debits_data)
    periodes.map do |periode_str|
      periode_date = Date.parse(periode_str)
      debit_record = debits_data[periode_date]
      debit_record && debit_record[1] ? debit_record[1].to_f : nil
    end
  end

  def map_periodes_to_parts_patronales(periodes, debits_data)
    periodes.map do |periode_str|
      periode_date = Date.parse(periode_str)
      debit_record = debits_data[periode_date]
      debit_record && debit_record[2] ? debit_record[2].to_f : nil
    end
  end

  def map_periodes_to_montant_echeancier(periodes, delais) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity
    # For each periode, find all active delais (date_creation < periode < date_echeance)
    # Deduplicate by date_creation and date_echeance, then sort by date_creation descending (newest first)
    # Take the first one (most recent) - this matches the legacy JS: delais(p).sort(...)[0]
    periodes.map do |periode_str|
      periode_date = Date.parse(periode_str)

      active_delais = delais.select do |delai|
        delai.date_creation < periode_date && periode_date < delai.date_echeance
      end

      # Deduplicate by date_creation and date_echeance (keep only unique date ranges)
      unique_delais = active_delais.uniq { |d| [d.date_creation, d.date_echeance] }

      # Sort by date_creation descending (newest first) - matches JS: (delai1.dateCreation<delai2.dateCreation)?1:-1
      unique_delais = unique_delais.sort_by(&:date_creation).reverse

      unique_delais.first&.montant_echeancier&.to_f
    end
  end

  def fetch_alert_history # rubocop:disable Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity,Metrics/AbcSize
    return if @company.siren.blank?

    lists = List.order(code: :desc)

    @alert_history = lists.map do |list|
      # Check if there's an entry for this siren and list
      entry = CompanyScoreEntry.find_by(siren: @company.siren, list_name: list.label)

      alert_level = if entry&.alert&.downcase == "alerte seuil f1"
                      "high"
                    elsif entry&.alert&.downcase == "alerte seuil f2"
                      "moderate"
                    else
                      "none"
                    end

      {
        list_name: list.label,
        alert_level: alert_level
      }
    end

    # Determine if button should be displayed
    @show_alert_history_button = should_show_alert_history_button?
  end

  def should_show_alert_history_button? # rubocop:disable Metrics/CyclomaticComplexity
    return false if @alert_history.blank?

    has_ever_been_detected = CompanyScoreEntry.exists?(siren: @company.siren)
    return false unless has_ever_been_detected

    current_alert_index = @alert_history.find_index { |item| %w[high moderate].include?(item[:alert_level]) }

    return @alert_history.any? { |item| %w[high moderate].include?(item[:alert_level]) } if current_alert_index.nil?

    alert_count = @alert_history.count { |item| %w[high moderate].include?(item[:alert_level]) }
    return false if alert_count == 1 # First alert, don't show button

    true
  end

  def urssaf_dataset_names
    [
      "Cotisations appelées",
      "Dette restante (part salariale)",
      "Dette restante (part patronale)",
      "Montant de l'échéancier du délai de paiement"
    ]
  end
end
