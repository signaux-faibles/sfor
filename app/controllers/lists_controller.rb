# rubocop:disable all
class ListsController < ApplicationController # rubocop:disable Metrics/ClassLength
  include SirenSiretRedirectable
  include ProcolStatusable
  include ListExportTrackable
  include MultiselectParseable

  STANDARD_ALERT_VALUES = CompanyList::STANDARD_ALERT_VALUES
  CRP_ALERT_VALUES = CompanyList::CRP_ALERT_VALUES

  before_action :set_multiselect_options, only: :show

  def index
    @lists = List.order(list_date: :desc)
  end

  def show # rubocop:disable Metrics/MethodLength
    @list = List.find(params[:id])

    parse_multiselect_params

    # Get search params
    @search_params = params.require(:search).permit(:q,
                                                    :effectif_min,
                                                    :dette_sociale_min, :libelle_procol,
                                                    :frequence_alerte, :niveau_alerte,
                                                    :premieres_alertes, :sans_entreprises_recentes,
                                                    :sans_delai_urssaf, :liste_retraitee,
                                                    :filters_open,
                                                    :cursor, :per_page,
                                                    departement_in: [],
                                                    forme_juridique: [],
                                                    section_activite_principale: []) if params[:search].present?
    @search_params ||= {}
    @selected_departements_json = @departements_options.select { |o| Array(@search_params[:departement_in]).include?(o[:value]) }.to_json
    @selected_sections_json = @section_options.select { |o| Array(@search_params[:section_activite_principale]).include?(o[:value]) }.to_json
    @selected_formes_json = @forme_options.select { |o| Array(@search_params[:forme_juridique]).include?(o[:value]) }.to_json

    # Parse cursor: format is "score:id" or just "id" for backward compatibility
    @cursor_score, @cursor_id = parse_cursor(@search_params[:cursor])
    @cursor_id = 0 if @cursor_id < 1
    @per_page = @search_params[:per_page].to_i
    @per_page = 20 if @per_page < 1
    @per_page = 100 if @per_page > 100 # Cap at 100 for performance

    # Start with companies in this list (from company_score_entries)
    # Use EXISTS subquery instead of JOIN + DISTINCT for better performance
    @companies = companies_in_list(@list)

    # Apply policy scope to restrict to user's departments
    @companies = policy_scope(@companies)

    # Apply all database filters
    @companies = apply_database_filters(@companies)

    # Alert breakdown is loaded asynchronously via Turbo Frame for better performance

    respond_to do |format|
      format.html do
        # company_lists is already joined by companies_in_list — score is a direct column.
        @companies = @companies.select("companies.*, company_lists.score")

        # Order by score DESC, then id ASC for stable pagination
        @companies = @companies.order("company_lists.score DESC NULLS LAST, companies.id ASC")

        # Apply cursor-based pagination: (score < cursor_score) OR (score = cursor_score AND id > cursor_id)
        if @cursor_id > 0
          if !@cursor_score.nil?
            @companies = @companies.where(
              "(company_lists.score < ?) OR (company_lists.score = ? AND companies.id > ?)",
              @cursor_score, @cursor_score, @cursor_id
            )
          else
            # Backward compatibility: if no score in cursor, just use id
            @companies = @companies.where("companies.id > ?", @cursor_id)
          end
        end

        # Log full query for EXPLAIN ANALYZE (copy-paste directly into psql)
        Rails.logger.warn "[ListsController#show] ===== EXPLAIN ANALYZE =====\nEXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)\n#{@companies.limit(@per_page + 1).to_sql};\n=========="

        # Load one extra to check if there's a next page
        companies_with_extra = @companies.limit(@per_page + 1).to_a

        # Check if there's a next page
        @has_next_page = companies_with_extra.size > @per_page

        # Remove the extra item if present
        companies_page = companies_with_extra.first(@per_page)

        # Format results for display (establishment count loaded via Turbo Frame)
        @results = companies_page.map do |company|
          {
            "siren" => company.siren,
            "nom_complet" => company.raison_sociale || company.siren,
            "id" => company.id,
            "score" => company.score
          }
        end

        # Set next cursor (score:id format) if there's a next page
        if @has_next_page && @results.any?
          last_result = @results.last
          @next_cursor = build_next_cursor(last_result)
        end

        # Enrichment is done per-result via Turbo Frames for better performance
      end
      format.xlsx do
        export_list(@companies)
      end
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to lists_path, alert: "Liste introuvable" # rubocop:disable Rails/I18nLocaleTexts
  rescue ActionController::ParameterMissing
    @search_params = {}
    @cursor_id = 0
    @cursor_score = nil
    @per_page = 20

    @companies = companies_in_list(@list)
    @companies = policy_scope(@companies)
    @companies = apply_database_filters(@companies)

    respond_to do |format|
      format.html do
        @companies = @companies.select("companies.*, company_lists.score")
        @companies = @companies.order("company_lists.score DESC NULLS LAST, companies.id ASC")

        Rails.logger.warn "[ListsController#show rescue] ===== EXPLAIN ANALYZE =====\nEXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)\n#{@companies.limit(@per_page + 1).to_sql};\n=========="

        companies_with_extra = @companies.limit(@per_page + 1).to_a
        @has_next_page = companies_with_extra.size > @per_page
        companies_page = companies_with_extra.first(@per_page)

        @results = companies_page.map do |company|
          {
            "siren" => company.siren,
            "nom_complet" => company.raison_sociale || company.siren,
            "id" => company.id,
            "score" => company.score
          }
        end

        if @has_next_page && @results.any?
          last_result = @results.last
          @next_cursor = build_next_cursor(last_result)
        end
      end
      format.xlsx do
        export_list(@companies)
      end
    end
  end

  def load_more
    @list = List.find(params[:id])

    parse_multiselect_params

    # Get search params (same as show action)
    @search_params = params.require(:search).permit(:q,
                                                    :effectif_min,
                                                    :dette_sociale_min, :libelle_procol,
                                                    :frequence_alerte, :niveau_alerte,
                                                    :premieres_alertes, :sans_entreprises_recentes,
                                                    :sans_delai_urssaf, :liste_retraitee,
                                                    :filters_open,
                                                    :cursor, :per_page,
                                                    departement_in: [],
                                                    forme_juridique: [],
                                                    section_activite_principale: []) if params[:search].present?
    @search_params ||= {}

    # Parse cursor: format is "score:id" or just "id" for backward compatibility
    @cursor_score, @cursor_id = parse_cursor(@search_params[:cursor])
    @cursor_id = 0 if @cursor_id < 1
    @per_page = @search_params[:per_page].to_i
    @per_page = 20 if @per_page < 1
    @per_page = 100 if @per_page > 100

    # Start with companies in this list
    @companies = companies_in_list(@list)
    @companies = policy_scope(@companies)
    @companies = apply_database_filters(@companies)

    # Join with company_score_entries to get score and order by score DESC
    # Use a subquery to get the latest score for each company in this list
    # company_lists is already joined by companies_in_list — score is a direct column.
    @companies = @companies.select("companies.*, company_lists.score")
    @companies = @companies.order("company_lists.score DESC NULLS LAST, companies.id ASC")

    # Apply cursor-based pagination: (score < cursor_score) OR (score = cursor_score AND id > cursor_id)
    if @cursor_id > 0
      if !@cursor_score.nil?
        @companies = @companies.where(
          "(company_lists.score < ?) OR (company_lists.score = ? AND companies.id > ?)",
          @cursor_score, @cursor_score, @cursor_id
        )
      else
        # Backward compatibility: if no score in cursor, just use id
        @companies = @companies.where("companies.id > ?", @cursor_id)
      end
    end

    # Load one extra to check if there's a next page
    companies_with_extra = @companies.limit(@per_page + 1).to_a
    @has_next_page = companies_with_extra.size > @per_page
    companies_page = companies_with_extra.first(@per_page)

    # Format results
    @results = companies_page.map do |company|
      {
        "siren" => company.siren,
        "nom_complet" => company.raison_sociale || company.siren,
        "id" => company.id,
        "score" => company.read_attribute(:score)
      }
    end

    # Set next cursor (score:id format) if there's a next page
    if @has_next_page && @results.any?
      last_result = @results.last
      @next_cursor = build_next_cursor(last_result)
    end

    respond_to do |format|
      format.turbo_stream # Renders load_more.turbo_stream.erb
      format.html # Fallback
    end
  end

  def enrich_company
    @list = List.find(params[:id])
    siren = params[:siren]

    return head :bad_request if siren.blank?

    # Get enrichment data for a single company
    @enrichment = enrich_single_company(siren)

    respond_to do |format|
      format.html # Renders enrich_company.html.erb for turbo_frame
    end
  end

  def company_count
    @list = List.find(params[:id])
    @count = filtered_company_count(@list)
    respond_to do |format|
      format.html # Renders company_count.html.erb for turbo_frame
    end
  end

  def alert_breakdown # rubocop:disable Metrics/MethodLength
    @list = List.find(params[:id])

    parse_multiselect_params

    # Get search params (same as show action)
    @search_params = params.require(:search).permit(:q,
                                                    :effectif_min,
                                                    :dette_sociale_min, :libelle_procol,
                                                    :niveau_alerte,
                                                    :premieres_alertes, :sans_entreprises_recentes,
                                                    :sans_delai_urssaf, :liste_retraitee,
                                                    :filters_open,
                                                    departement_in: [],
                                                    forme_juridique: [],
                                                    section_activite_principale: []) if params[:search].present?
    @search_params ||= {}

    # Start with companies in this list (from company_score_entries)
    # Use EXISTS subquery instead of JOIN + DISTINCT for better performance
    @companies = companies_in_list(@list)

    # Apply policy scope to restrict to user's departments
    @companies = policy_scope(@companies)

    # Apply all database filters
    @companies = apply_database_filters(@companies)

    # Calculate total count of filtered companies
    @total_count = @companies.count

    # Calculate alert breakdown from filtered results
    @alert_breakdown = calculate_alert_breakdown(@companies)

    respond_to do |format|
      format.html # Renders alert_breakdown.html.erb for turbo_frame
    end
  rescue ActionController::ParameterMissing
    @search_params = {}

    # Start with companies in this list (from company_score_entries)
    # Use EXISTS subquery instead of JOIN + DISTINCT for better performance
    @companies = companies_in_list(@list)

    # Apply policy scope to restrict to user's departments
    @companies = policy_scope(@companies)

    # Apply all database filters
    @companies = apply_database_filters(@companies)

    # Calculate total count of filtered companies
    @total_count = @companies.count

    # Calculate alert breakdown from filtered results
    @alert_breakdown = calculate_alert_breakdown(@companies)

    respond_to do |format|
      format.html
    end
  end

  private

  def filtered_company_count(list)
    companies = companies_in_list(list)
    companies = policy_scope(companies)
    companies = companies.where(
      "company_lists.alert IN (?)",
      CompanyList.alerts_visible_to_user(crp_member: crp_network_member?)
    )
    companies.select(:siren).distinct.count
  end

  def parse_multiselect_params
    parse_multiselect(:search, %w[departement_in section_activite_principale forme_juridique])
  end

  def set_multiselect_options
    @departements_options = current_user.geo_access.departments.order(:code).map { |d| { value: d.code, label: "#{d.code} - #{d.name}" } }
    @section_options = [
      { value: "A", label: "A - Agriculture, sylviculture et pêche" },
      { value: "B", label: "B - Industries extractives" },
      { value: "C", label: "C - Industrie manufacturière" },
      { value: "D", label: "D - Production et distribution d'électricité, de gaz, de vapeur et d'air conditionné" },
      { value: "E", label: "E - Production et distribution d'eau ; assainissement, gestion des déchets et dépollution" },
      { value: "F", label: "F - Construction" },
      { value: "G", label: "G - Commerce ; réparation d'automobiles et de motocycles" },
      { value: "H", label: "H - Transports et entreposage" },
      { value: "I", label: "I - Hébergement et restauration" },
      { value: "J", label: "J - Information et communication" },
      { value: "K", label: "K - Activités financières et d'assurance" },
      { value: "L", label: "L - Activités immobilières" },
      { value: "M", label: "M - Activités spécialisées, scientifiques et techniques" },
      { value: "N", label: "N - Activités de services administratifs et de soutien" },
      { value: "O", label: "O - Administration publique" },
      { value: "P", label: "P - Enseignement" },
      { value: "Q", label: "Q - Santé humaine et action sociale" },
      { value: "R", label: "R - Arts, spectacles et activités récréatives" },
      { value: "S", label: "S - Autres activités de services" },
      { value: "T", label: "T - Activités des ménages en tant qu'employeurs ; activités indifférenciées des ménages en tant que producteurs de biens et services pour usage propre" },
      { value: "U", label: "U - Activités extra-territoriales" }
    ]
    @forme_options = helpers.legal_forms_options.map { |code, label| { value: code, label: "#{code} - #{label}" } }
  end

  # Build base query for companies in a list via the company_lists join table.
  # company_lists is rebuilt from company_score_entries by rake lists:rebuild_company_lists
  # after each JSON score import. This gives a pre-computed, indexed (list_id, score)
  # lookup instead of a DISTINCT ON subquery over company_score_entries on every request.
  def companies_in_list(list)
    Company.joins(:company_lists).where(company_lists: { list_id: list.id })
  end

  def export_list(companies)
    track_list_export(@list, @search_params, companies.count)
    response.headers["Cache-Control"] = "no-store"
    send_data generate_excel(companies),
              filename: "#{@list.label.parameterize}.xlsx",
              type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
              disposition: "attachment"
  end

  def generate_excel(companies)
    Excel::ListGenerator.new(@list, companies, @search_params, current_user).generate
  end

  def apply_database_filters(companies) # rubocop:disable Metrics/MethodLength
    # NOTE: All filters below are combined (AND logic) - each filter narrows down the results
    # from the previous filters. The `companies` query is progressively refined.

    # Only meaningful detections (aligned with DetectionWidgetable / alert breakdown).
    companies = companies.where(
      "company_lists.alert IN (?)",
      CompanyList.alerts_visible_to_user(crp_member: crp_network_member?)
    )

    # Filter by search query (q) - SIREN or raison sociale
    if @search_params[:q].present?
      query = @search_params[:q].strip
      companies = companies.where(
        "companies.siren ILIKE ? OR companies.raison_sociale ILIKE ?",
        "%#{query}%", "%#{query}%"
      )
    end

    # Filter by section_activite_principale using company.naf_section (1-letter)
    if @search_params[:section_activite_principale].present? && @search_params[:section_activite_principale].is_a?(Array)
      sections = @search_params[:section_activite_principale].compact_blank
      companies = companies.where(naf_section: sections) if sections.any?
    end

    # Filter by forme_juridique (statut_juridique)
    if @search_params[:forme_juridique].present? && @search_params[:forme_juridique].is_a?(Array)
      statut_codes = @search_params[:forme_juridique].compact_blank
      companies = companies.where(statut_juridique: statut_codes) if statut_codes.any?
    end

    # Filter by department (company level)
    if @search_params[:departement_in].present? && @search_params[:departement_in].is_a?(Array)
      department_codes = @search_params[:departement_in].compact_blank
      companies = companies.where(department: department_codes) if department_codes.any?
    end

    # Filter by minimum effectif — uses the denormalized companies.latest_effectif
    # (kept in sync by rake companies:update_latest_effectif after each osf:sync_effectif_ent)
    if @search_params[:effectif_min].present?
      companies = companies.where("companies.latest_effectif >= ?", @search_params[:effectif_min].to_i)
    end

    # Filter by minimum dette sociale — uses the denormalized companies.social_debt_total
    # (kept in sync by rake companies:update_social_debt_total after each osf:sync_debit)
    if @search_params[:dette_sociale_min].present?
      dette_min = @search_params[:dette_sociale_min].to_f
      companies = companies.where("companies.social_debt_total >= ?", dette_min)
    end

    # Filter by libelle_procol — uses the denormalized companies.current_procol_status
    # (NULL means "In bonis"; kept in sync by rake companies:update_procol_status after each osf:sync_procol)
    if @search_params[:libelle_procol].present? && @search_params[:libelle_procol] != ""
      companies = if @search_params[:libelle_procol] == "In bonis"
                    companies.where(current_procol_status: nil)
                  else
                    companies.where(current_procol_status: @search_params[:libelle_procol])
                  end
    end

    # Filter by niveau_alerte — company_lists.alert is already joined by companies_in_list,
    # no need to hit company_score_entries at all.
    if @search_params[:niveau_alerte].present? && @search_params[:niveau_alerte] != ""
      companies = companies.where("company_lists.alert = ?", @search_params[:niveau_alerte])
    end

    # Filter by premieres_alertes (no detection in the last 18 months before this list)
    if @search_params[:premieres_alertes].present? && @search_params[:premieres_alertes] == "1"
      cutoff_date = (@list.list_date || Date.current) - 18.months
      current_list_date = @list.list_date || Date.current

      # A company is a "première alerte" if it has a current F1/F2 alert and has NOT appeared
      # in any other list within the last 18 months before the current list date with F1/F2.
      # Plans/Ratios never qualify and never count as prior detections.
      companies = companies.where(company_lists: { alert: CompanyList::STANDARD_ALERT_VALUES })

      recent_list_ids = List
        .where("list_date > ? AND list_date < ?", cutoff_date, current_list_date)
        .where.not(label: @list.label)
        .pluck(:id)

      if recent_list_ids.present?
        recently_appeared_sirens = CompanyList
          .where(list_id: recent_list_ids)
          .where(alert: CompanyList::STANDARD_ALERT_VALUES)
          .select(:siren)
        companies = companies.where.not(siren: recently_appeared_sirens)
      end
      # If no recent list IDs found, all companies are first alerts — no filter needed.
    end

    # Filter by sans_entreprises_recentes (exclude companies created after threshold date)
    if @search_params[:sans_entreprises_recentes].present? && @search_params[:sans_entreprises_recentes] == "1"
      filter_date = AppSetting.current&.entreprises_recentes_filter_date || (Date.current - 3.years)
      # Exclude companies created after filter_date, but include companies with NULL creation date
      companies = companies.where("creation IS NULL OR creation <= ?", filter_date)
    end

    # Filter by sans_delai_urssaf (exclude companies whose URSSAF delay extends past the list date)
    if @search_params[:sans_delai_urssaf].present? && @search_params[:sans_delai_urssaf] == "1" && @list.list_date.present?
      companies = companies.where(
        "companies.delai_urssaf_until IS NULL OR companies.delai_urssaf_until <= ?", @list.list_date
      )
    end

    # Filter by liste_retraitee (only show companies in SjcfCompany for this list)
    if @search_params[:liste_retraitee].present? && @search_params[:liste_retraitee] == "1"
      # Use EXISTS subquery to avoid materializing sirens in Ruby
      companies = companies.where(
        "EXISTS (
          SELECT 1 FROM sjcf_companies sc
          WHERE sc.siren = companies.siren
          AND sc.libelle_liste = ?
        )", @list.label
      )
    end

    companies
  end

  def enrich_results_with_tracking_status(results) # rubocop:disable Metrics/MethodLength
    return if results.blank?

    # Extract all sirens from results
    sirens = results.pluck("siren").compact.uniq
    return if sirens.blank?

    # Count trackings by state for each siren
    tracking_counts = EstablishmentTracking
                      .kept
                      .joins(:establishment)
                      .where(establishments: { siren: sirens })
                      .group("establishments.siren", "establishment_trackings.state")
                      .count

    # Initialize counts for each siren
    tracking_by_siren = {}
    sirens.each do |siren|
      tracking_by_siren[siren] = {
        in_progress: 0,
        under_surveillance: 0,
        completed: 0
      }
    end

    # Populate counts from grouped query results
    tracking_counts.each do |(siren, state), count|
      case state
      when "in_progress"
        tracking_by_siren[siren][:in_progress] = count
      when "under_surveillance"
        tracking_by_siren[siren][:under_surveillance] = count
      when "completed"
        tracking_by_siren[siren][:completed] = count
      end
    end

    # Enrich each result with tracking counts
    results.each do |result|
      siren = result["siren"]
      counts = tracking_by_siren[siren] || { in_progress: 0, under_surveillance: 0, completed: 0 }
      result["tracking_in_progress_count"] = counts[:in_progress]
      result["tracking_under_surveillance_count"] = counts[:under_surveillance]
      result["tracking_completed_count"] = counts[:completed]
      result["has_tracking_in_progress"] = (counts[:in_progress]).positive?
    end
  end

  def enrich_results_with_alert_levels(results) # rubocop:disable Metrics/MethodLength
    return if results.blank?

    # Extract all sirens from results
    sirens = results.pluck("siren").compact.uniq
    return if sirens.blank?

    # Find all CompanyScoreEntry records for these sirens in the current list
    alert_entries = {}
    CompanyScoreEntry
      .where(siren: sirens, list_name: @list.label)
      .where.not(alert: nil)
      .order(created_at: :desc)
      .pluck(:siren, :alert)
      .each do |siren, alert|
        # Only keep the first (most recent) entry for each siren
        alert_entries[siren] ||= alert
      end

    # Enrich each result with alert level
    results.each do |result|
      alert = alert_entries[result["siren"]]
      next unless alert

      case alert.downcase
      when "alerte seuil f1"
        result["alert_level"] = "elevee"
      when "alerte seuil f2"
        result["alert_level"] = "moderee"
      when "plans"
        result["alert_level"] = "plans"
      when "ratios"
        result["alert_level"] = "ratios"
      end
    end
  end

  def enrich_results_with_first_alert_flag(results)
    return if results.blank?

    sirens = results.pluck("siren").compact.uniq
    return if sirens.blank?

    cutoff_date = (@list.list_date || Date.current) - 18.months
    current_list_date = @list.list_date || Date.current

    # A company is a "première alerte" if it has NOT appeared in any other list
    # within the last 18 months before the current list date with a meaningful alert.
    sirens_in_recent_lists = CompanyScoreEntry
                             .joins(:list)
                             .where(siren: sirens)
                             .where.not(list_name: @list.label)
                             .where("lists.list_date > ? AND lists.list_date < ?", cutoff_date, current_list_date)
                             .where(company_score_entries: { alert: CompanyList::STANDARD_ALERT_VALUES })
                             .distinct
                             .pluck(:siren)
                             .to_set

    first_time_sirens = sirens.to_set - sirens_in_recent_lists

    results.each do |result|
      result["is_first_alert"] = CompanyList.first_alert_eligible?(result["alert"]) &&
                                 first_time_sirens.include?(result["siren"])
    end
  end

  def calculate_alert_breakdown(companies_query)
    # company_lists has one row per (siren, list) — no DISTINCT needed.
    # Uses the covering index on (list_id, score) INCLUDE (siren, alert, ...) for an index-only scan.
    if crp_network_member?
      counts = CompanyList
               .where(list_id: @list.id)
               .where(siren: companies_query.select(:siren))
               .where(alert: STANDARD_ALERT_VALUES + CRP_ALERT_VALUES)
               .pick(
                 Arel.sql("COUNT(CASE WHEN alert = 'Alerte seuil F1' THEN 1 END)"),
                 Arel.sql("COUNT(CASE WHEN alert = 'Alerte seuil F2' THEN 1 END)"),
                 Arel.sql("COUNT(CASE WHEN alert = 'Plans' THEN 1 END)"),
                 Arel.sql("COUNT(CASE WHEN alert = 'Ratios' THEN 1 END)")
               ) || [0, 0, 0, 0]

      {
        alerte_elevee: counts[0].to_i,
        alerte_moderee: counts[1].to_i,
        alerte_plans: counts[2].to_i,
        alerte_ratios: counts[3].to_i
      }
    else
      counts = CompanyList
               .where(list_id: @list.id)
               .where(siren: companies_query.select(:siren))
               .where(alert: STANDARD_ALERT_VALUES)
               .pick(
                 Arel.sql("COUNT(CASE WHEN alert = 'Alerte seuil F1' THEN 1 END)"),
                 Arel.sql("COUNT(CASE WHEN alert = 'Alerte seuil F2' THEN 1 END)")
               ) || [0, 0]

      {
        alerte_elevee: counts[0].to_i,
        alerte_moderee: counts[1].to_i
      }
    end
  end

  def enrich_single_company(siren) # rubocop:disable Metrics/MethodLength
    enrichment = {
      is_first_alert: false,
      alert_level: nil,
      tracking_in_progress_count: 0,
      tracking_under_surveillance_count: 0,
      tracking_completed_count: 0,
      nombre_etablissements_ouverts: 0,
      procol_status: nil
    }

    # Get tracking counts
    tracking_counts = EstablishmentTracking
                      .kept
                      .joins(:establishment)
                      .where(establishments: { siren: siren })
                      .group("establishment_trackings.state")
                      .count

    tracking_counts.each do |state, count|
      case state
      when "in_progress"
        enrichment[:tracking_in_progress_count] = count
      when "under_surveillance"
        enrichment[:tracking_under_surveillance_count] = count
      when "completed"
        enrichment[:tracking_completed_count] = count
      end
    end

    # Get alert level
    alert_entry = CompanyScoreEntry
                  .where(siren: siren, list_name: @list.label)
                  .where.not(alert: nil)
                  .order(created_at: :desc)
                  .first

    if alert_entry
      case alert_entry.alert&.downcase
      when "alerte seuil f1"
        enrichment[:alert_level] = "elevee"
      when "alerte seuil f2"
        enrichment[:alert_level] = "moderee"
      when "plans"
        enrichment[:alert_level] = "plans"
      when "ratios"
        enrichment[:alert_level] = "ratios"
      end
    end

    # Get first alert flag (no detection in the last 18 months before this list)
    cutoff_date = (@list.list_date || Date.current) - 18.months
    current_list_date = @list.list_date || Date.current
    siren_in_recent_lists = CompanyScoreEntry
                            .joins(:list)
                            .where(siren: siren)
                            .where.not(list_name: @list.label)
                            .where("lists.list_date > ? AND lists.list_date < ?", cutoff_date, current_list_date)
                            .where(company_score_entries: { alert: CompanyList::STANDARD_ALERT_VALUES })
                            .exists?

    enrichment[:is_first_alert] = CompanyList.first_alert_eligible?(alert_entry&.alert) && !siren_in_recent_lists

    # Get establishment count
    enrichment[:nombre_etablissements_ouverts] = Establishment
                                                 .where(siren: siren, is_active: true)
                                                 .count

    # Get procol status
    enrichment[:procol_status] = procol_status_for_siren(siren)

    enrichment
  end

  def crp_network_member?
    current_user&.crp_network_member?
  end

  def parse_cursor(raw_cursor)
    cursor_str = raw_cursor.to_s
    return [nil, 0] if cursor_str.blank?

    if cursor_str.include?(":")
      score_part, id_part = cursor_str.split(":", 2)
      parsed_score = score_part.present? ? score_part.to_f : nil
      parsed_id = id_part.to_i
      [parsed_score, parsed_id]
    else
      [nil, cursor_str.to_i]
    end
  end

  def build_next_cursor(result)
    score = result["score"]
    id = result["id"]
    score.nil? ? id.to_s : "#{score}:#{id}"
  end
end
