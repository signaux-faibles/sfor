class EstablishmentsController < ApplicationController # rubocop:disable Metrics/ClassLength
  include ProcolStatusable

  before_action :set_establishment,
                only: %i[show data_effectif_ap_widget data_urssaf_widget establishment_trackings_list_widget]

  def index
    @q = Establishment.ransack(params[:q])
    @establishments = @q.result(distinct: true)
  end

  def show
    load_trackings
    @procol_status = calculate_procol_status
  end

  def insee_widget
    @establishment = Establishment.find_by!(siret: params[:siret])
    fetch_insee_data
    render partial: "insee_widget"
  end

  def data_urssaf_widget # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    start_date = 24.months.ago.beginning_of_month.to_date
    periodes, @formatted_periodes = generate_formatted_periods(start_date)

    cotisations_data = fetch_cotisations_data(start_date)
    debits_data = fetch_debits_data(start_date)
    delais = fetch_delais_data(start_date)

    @cotisations = forward_fill(map_periodes_to_cotisations(periodes, cotisations_data))
    @parts_salariales = forward_fill(map_periodes_to_parts_salariales(periodes, debits_data))
    @parts_patronales = forward_fill(map_periodes_to_parts_patronales(periodes, debits_data))
    @montant_echeancier = forward_fill(map_periodes_to_montant_echeancier(periodes, delais))

    # Set arrays to empty if they only contain nil values
    @cotisations = [] if @cotisations.all?(&:nil?)
    @parts_salariales = [] if @parts_salariales.all?(&:nil?)
    @parts_patronales = [] if @parts_patronales.all?(&:nil?)
    @montant_echeancier = [] if @montant_echeancier.all?(&:nil?)

    @dataset_names = urssaf_dataset_names

    render partial: "data_urssaf_widget"
  end

  def data_effectif_ap_widget # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    start_date = 24.months.ago.beginning_of_month.to_date
    periodes, @formatted_periodes = generate_formatted_periods(start_date)

    effectifs_data = fetch_effectifs_data(start_date)
    ap_data = fetch_ap_data(start_date)

    @effectifs = map_periodes_to_effectifs(periodes, effectifs_data)
    @consommation_ap = map_periodes_to_consommation(periodes, ap_data)
    @autorisation_ap = map_periodes_to_autorisation(periodes, ap_data)

    # Set arrays to empty if they only contain nil values
    @effectifs = [] if @effectifs.all?(&:nil?)
    @consommation_ap = [] if @consommation_ap.all?(&:nil?)
    @autorisation_ap = [] if @autorisation_ap.all?(&:nil?)

    @dataset_names = effectif_ap_dataset_names

    render partial: "data_effectif_ap_widget"
  end

  def establishment_trackings_list_widget
    # load_trackings uses policy_scope via load_trackings_by_state
    load_trackings
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
    # Custom authorization logic:
    # 1. If the establishment is in user's departments, show all trackings
    # 2. If the establishment is not in user's departments but user is referent/participant, show all trackings
    # 3. Otherwise, show none
    all_establishment_trackings = @establishment.establishment_trackings

    can_see_trackings = false

    # Check if establishment is in user's departments
    can_see_trackings = true if current_user.department_ids.include?(@establishment.department&.id)

    # Check if user is referent or participant in any tracking of the establishment
    if !can_see_trackings && all_establishment_trackings.with_user_as_referent_or_participant(current_user).exists?
      can_see_trackings = true
    end

    @authorized_trackings = can_see_trackings ? all_establishment_trackings : EstablishmentTracking.none

    @in_progress_trackings = load_trackings_by_state(:in_progress)
    @completed_trackings = load_trackings_by_state(:completed)
    @under_surveillance_trackings = load_trackings_by_state(:under_surveillance)
  end

  def load_trackings_by_state(state)
    @authorized_trackings
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
    @date_fermeture_formatted = Time.zone.at(date_fermeture).to_date.strftime("%d/%m/%Y") if date_fermeture.present?
  rescue StandardError
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

  def fetch_cotisations_data(start_date)
    # Normalize periode to beginning of month to match generated periods
    cotisations = OsfCotisation
                  .where(siret: @establishment.siret)
                  .where(periode: start_date..)
                  .order(:periode)
                  .pluck(:periode, :du)

    cotisations.each_with_object({}) do |(periode, du), hash|
      periode_normalized = periode.beginning_of_month
      hash[periode_normalized] = (hash[periode_normalized] || 0) + (du || 0)
    end
  end

  def fetch_debits_data(start_date)
    # Normalize periode to beginning of month to match generated periods
    debits = OsfDebit
             .where(siret: @establishment.siret)
             .where(periode: start_date..)
             .order(:periode)
             .pluck(:periode, :part_ouvriere, :part_patronale)

    debits.index_by { |row| row[0].beginning_of_month }
  end

  def fetch_delais_data(start_date)
    # Fetch all delais that might be active during the period range
    # A delai is active if: date_creation < periode < date_echeance
    # We need to fetch delais where the date range overlaps with our period range
    end_date = Date.current.end_of_month
    OsfDelai
      .where(siret: @establishment.siret)
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

  def forward_fill(array)
    # Forward-fill: if a period has a value and the next period doesn't, keep the value from the previous period
    # But stop forward-filling after the last period with actual data (don't fill to current date)
    last_value = nil
    last_actual_index = array.rindex { |v| !v.nil? } # Find the last index with actual data

    array.map.with_index do |value, index|
      # Only forward-fill if we haven't passed the last actual data point
      if value.nil? && !last_value.nil? && (last_actual_index.nil? || index <= last_actual_index)
        last_value
      else
        last_value = value unless value.nil?
        value
      end
    end
  end

  def urssaf_dataset_names
    [
      "Cotisations appelées",
      "Dette restante (part salariale)",
      "Dette restante (part patronale)",
      "Montant de l'échéancier du délai de paiement"
    ]
  end

  def calculate_procol_status
    procol_status_for_siren(@establishment.siren)
  end
end
