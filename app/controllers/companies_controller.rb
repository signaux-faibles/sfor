class CompaniesController < ApplicationController # rubocop:disable Metrics/ClassLength
  include ProcolStatusable
  include DetectionWidgetable
  include OutOfZoneTrackable
  include DebitFreshnessable
  include ForwardFillable

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
    load_company_active_trackings
    track_out_of_zone_access(@company)
  end

  def insee_widget
    fetch_insee_data
    render partial: "insee_widget"
  end

  def detection_widget
    last_list, entry = fetch_last_list_and_entry
    return head :no_content unless last_list && entry

    @criticite = calculate_criticite(entry)
    @data_date = format_data_date(last_list, entry)

    render partial: "detection_widget"
  end

  def feedback_detection_widget
    last_list = latest_list_or_render_error
    return unless last_list

    load_feedback_entry_and_reasons(last_list)
    @existing_rating = existing_rating_for_list(last_list)

    if request.post?
      handle_feedback_submission(last_list)
    else
      render partial: "feedback_detection_widget"
    end
  end

  def handle_feedback_submission(list)
    @rating_reasons = RatingReason.order(:code)
    existing_rating = existing_rating_for_list(list)
    return render_existing_rating(existing_rating) if existing_rating

    useful = useful_param?
    error_message = feedback_validation_error(useful)
    return render_feedback_error(error_message) if error_message

    rating = create_feedback_rating(list, useful)
    associate_rating_reasons(rating) unless useful

    @existing_rating = rating
    render partial: "feedback_detection_widget"
  rescue StandardError
    render_feedback_error("Une erreur est survenue. Veuillez réessayer plus tard.")
  end

  def history_detection_widget
    data = Companies::AlertHistoryBuilder.new(@company).build
    @alert_history = data[:alert_history]
    @show_alert_history_button = data[:show_alert_history_button]

    render partial: "history_detection_widget"
  end

  def waterfall_detection_widget
    last_list, entry = fetch_last_list_and_entry
    return render partial: "waterfall_detection_widget", locals: { error: "Aucune liste disponible" } unless last_list

    @entry = entry
    return render partial: "waterfall_detection_widget",
                  locals: { error: "Aucune donnée disponible pour cette entreprise" } unless entry

    data = Companies::WaterfallChartBuilder.new(entry).build
    @labels = data[:labels]
    @values = data[:values]
    @seuils = data[:seuils]
    @criticite = calculate_criticite(entry)
    @data_date = format_data_date(last_list, entry)

    render partial: "waterfall_detection_widget"
  end

  def data_urssaf_widget
    @company = Company.find_by!(siren: params[:siren])
    start_date = 24.months.ago.beginning_of_month.to_date
    periodes, @formatted_periodes = Companies::PeriodsBuilder.build(start_date)

    data = Companies::UrssafSeriesBuilder.new(
      company: @company,
      start_date: start_date,
      periodes: periodes,
      debit_freshness_index: method(:debit_freshness_index),
      cotisation_freshness_index: cotisation_freshness_index(periodes),
      delai_freshness_index: delai_freshness_index(periodes),
      forward_fill: method(:forward_fill)
    ).build

    @cotisations = data[:cotisations]
    @parts_salariales = data[:parts_salariales]
    @parts_patronales = data[:parts_patronales]
    @montant_echeancier = data[:montant_echeancier]
    @dataset_names = urssaf_dataset_names

    render partial: "data_urssaf_widget"
  end

  def data_effectif_ap_widget
    @company = Company.find_by!(siren: params[:siren])
    start_date = 24.months.ago.beginning_of_month.to_date
    periodes, @formatted_periodes = Companies::PeriodsBuilder.build(start_date)

    data = Companies::EffectifApSeriesBuilder.new(
      company: @company,
      start_date: start_date,
      periodes: periodes,
      effectif_freshness_index: effectif_ent_freshness_index(periodes),
      ap_freshness_index: ap_freshness_index(periodes)
    ).build

    @effectifs = data[:effectifs]
    @consommation_ap = data[:consommation_ap]
    @autorisation_ap = data[:autorisation_ap]
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

    all_company_trackings = EstablishmentTracking.where(establishment: @establishments)
    @can_see_trackings = can_see_company_trackings?(all_company_trackings)
    @has_any_trackings = all_company_trackings.exists?
    @establishment_trackings = @can_see_trackings ? all_company_trackings : EstablishmentTracking.none

    load_tracking_states
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

  def latest_list_or_render_error
    last_list = List.order(code: :desc).first
    return last_list if last_list

    render partial: "feedback_detection_widget", locals: { error: "Aucune liste disponible" }
    nil
  end

  def load_feedback_entry_and_reasons(list)
    @entry = CompanyScoreEntry.find_by(siren: @company.siren, list_name: list.label)
    @rating_reasons = RatingReason.order(:code)
  end

  def existing_rating_for_list(list)
    CompanyListRating.find_by(
      siren: @company.siren,
      list_name: list.label,
      user_email: current_user.email
    )
  end

  def render_existing_rating(existing_rating)
    @existing_rating = existing_rating
    render partial: "feedback_detection_widget", status: :unprocessable_entity
  end

  def useful_param?
    params[:useful] == "true" || params[:useful] == true
  end

  def feedback_validation_error(useful)
    return if useful || params[:raisons].present?

    "Vous devez cocher au moins une raison."
  end

  def render_feedback_error(message)
    @error = message
    render partial: "feedback_detection_widget", status: :unprocessable_entity
  end

  def create_feedback_rating(list, useful)
    CompanyListRating.create!(
      siren: @company.siren,
      list_name: list.label,
      user_email: current_user.email,
      user_segment: current_user.segment.name,
      useful: useful,
      comment: params[:precisions]
    )
  end

  def associate_rating_reasons(rating)
    return if params[:raisons].blank?

    params[:raisons].each do |reason_code|
      reason = RatingReason.find_by(code: reason_code)
      next unless reason

      RatingReasonsRating.create!(
        rating_id: rating.id,
        reason_id: reason.id
      )
    end
  end

  def can_see_company_trackings?(all_company_trackings)
    return true if @establishments.joins(:department).exists?(departments: { id: current_user.department_ids })

    all_company_trackings.with_user_as_referent_or_participant(current_user).exists?
  end

  def load_tracking_states
    @in_progress_trackings = @establishment_trackings.in_progress
    @under_surveillance_trackings = @establishment_trackings.under_surveillance
    @active_trackings = @establishment_trackings.where(state: %w[in_progress under_surveillance])
    @completed_trackings = @establishment_trackings.completed
  end

  def initialize_empty_establishments_data
    @enriched_establishments = []
    @paginated_establishments = Kaminari.paginate_array([]).page(1).per(15)
    @total_establishments = 0
    @active_establishments = 0
  end

  def set_company
    @company = Company.find_by!(siren: params[:siren])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "Cette fiche entreprise n'existe pas dans SignauxFaibles" # rubocop:disable Rails/I18nLocaleTexts
    redirect_back(fallback_location: home_path)
  end

  def fetch_insee_data
    data = Companies::InseeDataBuilder.new(@company).build
    @insee_data = data[:insee_data]
    @date_fermeture_formatted = data[:date_fermeture_formatted]
  end

  def fetch_financial_data
    data = Companies::FinancialDataBuilder.new(@company).build
    @dates = data[:dates]
    @formatted_dates = data[:formatted_dates]
    @financial_fields = data[:financial_fields]
    @financial_fields_graph = data[:financial_fields_graph]
    @datasets = data[:datasets]
    @datasets_graph = data[:datasets_graph]
    @dataset_names = data[:dataset_names]
    @dataset_names_graph = data[:dataset_names_graph]
    @light_colors = data[:light_colors]
    @dark_colors = data[:dark_colors]
    @error = data[:error]
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

  def fetch_establishments_data
    return initialize_empty_establishments_data if @company.siren.blank?

    establishments = @company.establishments_ordered
    @paginated_establishments = establishments.page(params[:page]).per(10)
    @total_establishments = establishments.count
    @active_establishments = establishments.where(is_active: true).count

    @enriched_establishments = Companies::EstablishmentEnrichmentBuilder.new(@paginated_establishments).build
  rescue StandardError
    initialize_empty_establishments_data
  end

  def effectif_ap_dataset_names
    [
      "Effectifs (salariés)",
      "Consommation d'activité partielle (ETP)",
      "Autorisation d'activité partielle (ETP)"
    ]
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

  def load_company_active_trackings
    # Check if there are any active trackings (in_progress or under_surveillance) for any establishment of the company
    # Custom authorization logic:
    # 1. If one of the establishments of the company is in the user departments, show all trackings
    # 2. If the user is referent or participant in one of the existing trackings, show all trackings
    # 3. Otherwise, show none
    all_company_trackings = EstablishmentTracking.where(establishment: @establishments)

    can_see_trackings = false

    # Check if any establishment is in user's departments
    can_see_trackings = true if @establishments.joins(:department).exists?(departments: { id: current_user.department_ids })

    # Check if user is referent or participant in any tracking of the company
    can_see_trackings = true if !can_see_trackings && all_company_trackings.with_user_as_referent_or_participant(current_user).exists?

    authorized_trackings = can_see_trackings ? all_company_trackings : EstablishmentTracking.none
    @in_progress_trackings = authorized_trackings.in_progress
    @under_surveillance_trackings = authorized_trackings.under_surveillance
  end
end
