class CompaniesController < ApplicationController # rubocop:disable Metrics/ClassLength
  include ProcolStatusable

  before_action :set_company,
                only: %i[show insee_widget financial_widget establishments_widget detection_widget
                         feedback_detection_widget history_detection_widget waterfall_detection_widget]

  def index
    initialize_search_params
    load_reference_data
    @companies = @q.result(distinct: true)
  end

  def show
    @establishments = @company.establishments_ordered
    load_company_badges
  end

  def insee_widget
    fetch_insee_data
    render partial: "insee_widget"
  end

  def detection_widget
    render partial: "detection_widget"
  end

  def feedback_detection_widget # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    last_list = List.order(code: :desc).first
    return render partial: "feedback_detection_widget", locals: { error: "Aucune liste disponible" } unless last_list

    entry = CompanyScoreEntry.find_by(siren: @company.siren, list_name: last_list.label)
    @entry = entry

    @rating_reasons = RatingReason.order(:code)

    @existing_rating = CompanyListRating.find_by(
      siren: @company.siren,
      list_name: last_list.label,
      user_email: current_user.email
    )

    if request.post?
      handle_feedback_submission(last_list)
    else
      render partial: "feedback_detection_widget"
    end
  end

  def handle_feedback_submission(list) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    @rating_reasons = RatingReason.order(:code)

    existing_rating = CompanyListRating.find_by(
      siren: @company.siren,
      list_name: list.label,
      user_email: current_user.email
    )

    if existing_rating
      @existing_rating = existing_rating
      render partial: "feedback_detection_widget", status: :unprocessable_entity
      return
    end

    useful = params[:useful] == "true" || params[:useful] == true

    if !useful && (params[:raisons].blank? || params[:raisons].empty?)
      @error = "Vous devez cocher au moins une raison."
      render partial: "feedback_detection_widget", status: :unprocessable_entity
      return
    end

    # Create the rating
    rating = CompanyListRating.create!(
      siren: @company.siren,
      list_name: list.label,
      user_email: current_user.email,
      user_segment: current_user.segment.name,
      useful: useful,
      comment: params[:precisions]
    )

    # Associate rating reasons if not useful
    if !useful && params[:raisons].present?
      params[:raisons].each do |reason_code|
        reason = RatingReason.find_by(code: reason_code)
        next unless reason

        RatingReasonsRating.create!(
          rating_id: rating.id,
          reason_id: reason.id
        )
      end
    end

    @existing_rating = rating
    render partial: "feedback_detection_widget"
  rescue StandardError => e
    Rails.logger.error "Error creating rating: #{e.message}"
    @error = "Une erreur est survenue. Veuillez réessayer plus tard."
    render partial: "feedback_detection_widget", status: :unprocessable_entity
  end

  def history_detection_widget
    fetch_alert_history

    render partial: "history_detection_widget"
  end

  def waterfall_detection_widget # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
    # Get the last list
    last_list = List.order(code: :desc).first
    return render partial: "waterfall_detection_widget", locals: { error: "Aucune liste disponible" } unless last_list

    # Find the CompanyScoreEntry for this company and last list
    entry = CompanyScoreEntry.find_by(siren: @company.siren, list_name: last_list.label)
    @entry = entry
    return render partial: "waterfall_detection_widget",
                  locals: { error: "Aucune donnée disponible pour cette entreprise" } unless entry

    # Get macro_expl data
    macro_expl = entry.macro_expl || {}

    # Map macro_expl keys to internal keys and labels
    key_mapping = {
      "Dettes-sociales" => { key: "dettes_sociales", label: "Dettes sociales" },
      "Données-financières" => { key: "sante_financiere", label: "Santé financière" },
      "Recours-à-l'activité-partielle" => { key: "ap", label: "Recours à l'activité partielle" },
      "Variation-de-l'effectif-de-l'entreprise" => { key: "effectif", label: "Variation de l'effectif de l'entreprise" }
    }

    # Build data hash from macro_expl
    data = {}
    macro_expl.each do |macro_key, value|
      data[key_mapping[macro_key][:key]] = value.to_f.round(1) if key_mapping[macro_key]
    end

    # Sort by value descending
    data_ordered = data.sort_by { |_key, value| value }.reverse.to_h

    @labels = []
    @values = []

    risk = 0
    val1 = 0

    # Build waterfall chart data
    data_ordered.each do |key, value|
      risk += value
      val2 = (val1 + value).round(0)

      # Find the label for this key
      label = key_mapping.values.find { |m| m[:key] == key }&.dig(:label)
      @labels << label if label

      @values << [val1.round(0), val2]
      val1 = val2
    end

    # Add the final risk score (from entry.score)
    # Use entry.score directly, or fallback to calculated risk if score is nil
    final_score = (entry.score&.to_f || risk).round(0)
    @values << [0, final_score]
    @labels << "Risque de défaillance (%)"

    # Get seuils from environment variables
    seuil_f2 = ENV.fetch("SEUIL_F2", "65").to_f
    seuil_f1 = ENV.fetch("SEUIL_F1", "88").to_f
    @seuils = [seuil_f2, seuil_f1]

    # Determine criticite from alert field
    @criticite = if entry.alert&.downcase == "alerte seuil f1"
                   "élevée"
                 elsif entry.alert&.downcase == "alerte seuil f2"
                   "modérée"
                 else
                   "faible"
                 end

    # Format data_date from list_date or created_at
    @data_date = if last_list.list_date
                   I18n.l(last_list.list_date, format: :long, locale: :fr)
                 elsif entry.created_at
                   I18n.l(entry.created_at.to_date, format: :long, locale: :fr)
                 else
                   "Date non disponible"
                 end

    render partial: "waterfall_detection_widget"
  end

  def data_urssaf_widget # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    @company = Company.find_by!(siren: params[:siren])

    start_date = 24.months.ago.beginning_of_month.to_date
    periodes, @formatted_periodes = generate_formatted_periods(start_date)

    cotisations_data = fetch_cotisations_data(start_date)
    debits_data = fetch_debits_data(start_date)
    delais = fetch_delais_data(start_date)

    @cotisations = round_values(forward_fill(map_periodes_to_cotisations(periodes, cotisations_data)))
    @parts_salariales = round_values(forward_fill(map_periodes_to_parts_salariales(periodes, debits_data)))
    @parts_patronales = round_values(forward_fill(map_periodes_to_parts_patronales(periodes, debits_data)))
    @montant_echeancier = round_values(forward_fill(map_periodes_to_montant_echeancier(periodes, delais)))
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

    @siege = @establishments.find_by(siege: true)

    @establishment_trackings = EstablishmentTracking.where(establishment: @establishments)

    # Trackings considered "actifs" : en cours ou sous surveillance
    @in_progress_trackings = @establishment_trackings.in_progress
    @under_surveillance_trackings = @establishment_trackings.under_surveillance
    @active_trackings = @establishment_trackings.where(state: %w[in_progress under_surveillance])
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

  def fetch_insee_data # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength
    return if @company.siren.blank?

    service = Api::InseeApiService.new
    @insee_data = service.fetch_unite_legale_by_siren(@company.siren)

    date_fermeture = @insee_data&.dig("data", "date_fermeture")
    @date_fermeture_formatted = Time.zone.at(date_fermeture).to_date.strftime("%d/%m/%Y") if date_fermeture.present?

    siege_data = service.fetch_unite_legale_by_siren_siege(@company.siren)
    if siege_data&.dig("data", "adresse").present?
      @insee_data["data"] ||= {}
      @insee_data["data"]["adresse"] = siege_data["data"]["adresse"]
    end
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

      # Only keep the specified financial fields
      allowed_fields = {
        "chiffre_d_affaires" => "Chiffre d'Affaires (€)",
        "ebit" => "Résultat d'exploitation (€)",
        "ebe" => "Excédent Brut d'exploitation (EBE) (€)",
        "resultat_net" => "Résultat net (€)",
        "marge_brute" => "Marge brute (€)",
        "taux_d_endettement" => "Taux d'endettement (%)",
        "ratio_de_liquidite" => "Ratio de liquidité (%)"
      }

      # Build datasets only for allowed fields
      @financial_fields = []
      @datasets = {}
      @dataset_names = {}

      allowed_fields.each do |field_key, field_label|
        # Check if at least one record has this field
        if records.any? { |r| r.key?(field_key) }
          @financial_fields << field_key
          values = records.map { |r| r[field_key] }
          @datasets[field_key] = values
          @dataset_names[field_key] = field_label
        end
      end

      @financial_fields.sort!

      @dataset_names_graph = @dataset_names.except("ratio_de_liquidite", "taux_d_endettement")
      @datasets_graph = @datasets.except("ratio_de_liquidite", "taux_d_endettement")
      @financial_fields_graph = @financial_fields - %w[ratio_de_liquidite taux_d_endettement]

    else
      @dates = []
      @formatted_dates = []
      @financial_fields = []
      @financial_fields_graph = []
      @datasets = {}
      @datasets_graph = {}
      @dataset_names = {}
      @dataset_names_graph = {}
    end
    @light_colors = ["#6A6AF4", "#E1000F", "#B7A73F", "#E18B76", "#00A95F"]
    @dark_colors = ["#6A6AF4", "#E1000F", "#B7A73F", "#E18B76", "#00A95F"]
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

  def fetch_establishments_data # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Metrics/CyclomaticComplexity
    if @company.siren.blank?
      @enriched_establishments = []
      @paginated_establishments = Kaminari.paginate_array([]).page(1).per(15)
      @total_establishments = 0
      @active_establishments = 0
      return
    end

    # Récupérer les établissements de la base de données et paginer
    establishments = @company.establishments_ordered
    @paginated_establishments = establishments.page(params[:page]).per(10)

    # Calculer les statistiques globales (tous les établissements, pas seulement la page courante)
    @total_establishments = establishments.count
    @active_establishments = establishments.where(is_active: true).count

    # Enrichir chaque établissement avec les données INSEE (seulement ceux de la page courante)
    @enriched_establishments = []

    @paginated_establishments.each do |establishment| # rubocop:disable Metrics/BlockLength
      service = Api::InseeApiService.new(siret: establishment.siret, siren: nil)
      api_data = service.fetch_establishment_by_siret(establishment.siret)

      # Extraire les données de statut depuis l'API INSEE
      insee_data = api_data&.dig("data")
      etat_administratif = insee_data&.dig("etat_administratif")
      date_fermeture_timestamp = insee_data&.dig("date_fermeture")

      # Formater la date de fermeture si elle existe
      date_fermeture_formatted = nil
      if date_fermeture_timestamp.present?
        date_fermeture_formatted = Time.zone.at(date_fermeture_timestamp).strftime("%d/%m/%Y")
      end

      # Combiner les données Rails avec les données API
      enriched_establishment = {
        rails_data: establishment,
        insee_data: insee_data,
        has_api_data: insee_data.present?,
        last_effectif: OsfEffectif.last_effectif_for_siret(establishment.siret),
        active_dette_urssaf: OsfDelai.active_dette_urssaf?(establishment.siret),
        active_activite_partielle: OsfAp.active_activite_partielle?(establishment.siret),
        etat_administratif: etat_administratif,
        date_fermeture_formatted: date_fermeture_formatted
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
        active_dette_urssaf: OsfDelai.active_dette_urssaf?(establishment.siret),
        active_activite_partielle: OsfAp.active_activite_partielle?(establishment.siret),
        etat_administratif: nil,
        date_fermeture_formatted: nil
      }
    end
  rescue StandardError => e
    Rails.logger.error "Erreur lors de la récupération des établissements: #{e.message}"
    @enriched_establishments = []
    @paginated_establishments = Kaminari.paginate_array([]).page(1).per(15)
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

  def forward_fill(array)
    # Forward-fill: if a period has a value and the next period doesn't, keep the value from the previous period
    last_value = nil
    array.map do |value|
      if value.nil? && !last_value.nil?
        last_value
      else
        last_value = value unless value.nil?
        value
      end
    end
  end

  def round_values(array)
    array.map { |value| value&.round }
  end

  def urssaf_dataset_names
    [
      "Cotisations appelées",
      "Dette restante (part salariale)",
      "Dette restante (part patronale)",
      "Montant de l'échéancier du délai de paiement"
    ]
  end

  def load_company_badges
    @alert_level = calculate_alert_level
    @procol_status = calculate_procol_status
    @is_first_alert = calculate_is_first_alert
  end

  def calculate_alert_level
    # Get the last list
    last_list = List.order(code: :desc).first
    return nil unless last_list

    # Find the CompanyScoreEntry for this company and last list
    entry = CompanyScoreEntry.find_by(siren: @company.siren, list_name: last_list.label)
    return nil unless entry&.alert

    case entry.alert.downcase
    when "alerte seuil f1"
      "elevee"
    when "alerte seuil f2"
      "moderee"
    end
  end

  def calculate_procol_status
    procol_status_for_siren(@company.siren)
  end

  def calculate_is_first_alert
    # Get the last list
    last_list = List.order(code: :desc).first
    return false unless last_list

    # Check if company appears in the current list
    current_entry = CompanyScoreEntry.exists?(siren: @company.siren, list_name: last_list.label)
    return false unless current_entry

    # Check if company appears in other lists
    other_entries = CompanyScoreEntry.where(siren: @company.siren)
                                     .where.not(list_name: last_list.label)
                                     .exists?

    # If no other entries, it's a first alert
    !other_entries
  end
end
