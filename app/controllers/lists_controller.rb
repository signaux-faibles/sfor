class ListsController < ApplicationController # rubocop:disable Metrics/ClassLength
  include SirenSiretRedirectable
  include ProcolStatusable
  def index
    @lists = List.order(label: :asc)
  end

  def show # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
    @list = List.find(params[:id])

    # Get search params
    @search_params = params.require(:search).permit(:q,
                                                    :effectif_min, :score_min,
                                                    :dette_sociale_min, :libelle_procol,
                                                    :frequence_alerte, :niveau_alerte,
                                                    :premieres_alertes, :sans_entreprises_recentes,
                                                    :sans_delai_urssaf, :liste_retraitee,
                                                    :page, :per_page,
                                                    departement_in: [],
                                                    forme_juridique: [],
                                                    section_activite_principale: []) if params[:search].present?
    @search_params ||= {}

    # Check if search query is a valid SIREN or SIRET and redirect if so
    redirect_if_siren_or_siret(@search_params[:q])

    @page = @search_params[:page].to_i
    @page = 1 if @page < 1
    @per_page = @search_params[:per_page].to_i
    @per_page = 10 if @per_page < 1

    # Start with companies in this list (from company_score_entries)
    @companies = Company.joins(:company_score_entries)
                        .where(company_score_entries: { list_name: @list.label })
                        .distinct

    # Apply policy scope to restrict to user's departments
    @companies = policy_scope(@companies)

    # Apply all database filters
    @companies = apply_database_filters(@companies)

    # Alert breakdown is loaded asynchronously via Turbo Frame for better performance

    respond_to do |format|
      format.html do
        # Paginate (no includes needed - establishment counts loaded via Turbo Frame)
        @companies = @companies.page(@page).per(@per_page)

        Rails.logger.info "companies: #{@companies.inspect}"

        # Format results for display (establishment count loaded via Turbo Frame)
        @results = @companies.map do |company|
          {
            "siren" => company.siren,
            "nom_complet" => company.raison_sociale || company.siren
          }
        end

        @pagination = {
          page: @page,
          per_page: @per_page,
          total_pages: @companies.total_pages,
          total_results: @companies.total_count
        }

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
    @page = 1
    @per_page = 10

    # Start with companies in this list (from company_score_entries)
    @companies = Company.joins(:company_score_entries)
                        .where(company_score_entries: { list_name: @list.label })
                        .distinct

    # Apply policy scope to restrict to user's departments
    @companies = policy_scope(@companies)

    # Apply all database filters
    @companies = apply_database_filters(@companies)

    # Alert breakdown is loaded asynchronously via Turbo Frame for better performance

    respond_to do |format|
      format.html do
        # Paginate
        @companies = @companies.includes(:establishments).page(@page).per(@per_page)

        # Format results for display (establishment count loaded via Turbo Frame)
        @results = @companies.map do |company|
          {
            "siren" => company.siren,
            "nom_complet" => company.raison_sociale || company.siren
          }
        end

        @pagination = {
          page: @page,
          per_page: @per_page,
          total_pages: @companies.total_pages,
          total_results: @companies.total_count
        }

        # Enrichment is done per-result via Turbo Frames for better performance
      end
      format.xlsx do
        export_list(@companies)
      end
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

  def alert_breakdown # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    @list = List.find(params[:id])

    # Get search params (same as show action)
    @search_params = params.require(:search).permit(:q,
                                                    :effectif_min, :score_min,
                                                    :dette_sociale_min, :libelle_procol,
                                                    :frequence_alerte, :niveau_alerte,
                                                    :premieres_alertes, :sans_entreprises_recentes,
                                                    :sans_delai_urssaf, :liste_retraitee,
                                                    departement_in: [],
                                                    forme_juridique: [],
                                                    section_activite_principale: []) if params[:search].present?
    @search_params ||= {}

    # Start with companies in this list (from company_score_entries)
    @companies = Company.joins(:company_score_entries)
                        .where(company_score_entries: { list_name: @list.label })
                        .distinct

    # Apply policy scope to restrict to user's departments
    @companies = policy_scope(@companies)

    # Apply all database filters
    @companies = apply_database_filters(@companies)

    # Calculate alert breakdown from filtered results
    @alert_breakdown = calculate_alert_breakdown(@companies)

    respond_to do |format|
      format.html # Renders alert_breakdown.html.erb for turbo_frame
    end
  rescue ActionController::ParameterMissing
    @search_params = {}

    # Start with companies in this list (from company_score_entries)
    @companies = Company.joins(:company_score_entries)
                        .where(company_score_entries: { list_name: @list.label })
                        .distinct

    # Apply policy scope to restrict to user's departments
    @companies = policy_scope(@companies)

    # Apply all database filters
    @companies = apply_database_filters(@companies)

    # Calculate alert breakdown from filtered results
    @alert_breakdown = calculate_alert_breakdown(@companies)

    respond_to do |format|
      format.html
    end
  end

  private

  def export_list(companies)
    all_companies = companies.includes(:establishments, :company_score_entries,
                                       establishments: %i[department establishment_trackings])
    response.headers["Cache-Control"] = "no-store"
    send_data generate_excel(all_companies),
              filename: "#{@list.label.parameterize}.xlsx",
              type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
              disposition: "attachment"
  end

  def generate_excel(companies)
    Excel::ListGenerator.new(@list, companies, @search_params, current_user).generate
  end

  def apply_database_filters(companies) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    # NOTE: All filters below are combined (AND logic) - each filter narrows down the results
    # from the previous filters. The `companies` query is progressively refined.

    # Systematically exclude companies with excluded NAF codes
    excluded_naf_codes = %w[
      84.11Z 84.12Z 84.21Z 84.22Z 84.23Z 84.24Z 84.25Z 84.13Z 84.30A 84.30B 84.30C
      94.91Z 94.92Z 94.20Z 94.11Z 94.12Z
      64.11Z 64.19Z 64.30Z 64.91Z 64.92Z 64.99Z 65.11Z 65.12Z 65.20Z 65.30Z 66.11Z 66.12Z 66.19A 66.19B 66.21Z 66.22Z
      66.29Z 66.30Z 85.10Z 85.20Z 85.31Z 85.32Z 85.41Z 85.42Z
      99.00Z
    ]

    # TODO : update this to companies.where.not(naf_code: excluded_naf_codes) when naf_code is populated
    companies = companies.where("naf_code IS NULL OR naf_code NOT IN (?)", excluded_naf_codes)

    # Filter by search query (q) - SIREN or raison sociale
    if @search_params[:q].present?
      query = @search_params[:q].strip
      companies = companies.where(
        "companies.siren ILIKE ? OR companies.raison_sociale ILIKE ?",
        "%#{query}%", "%#{query}%"
      )
    end

    # Filter by section_activite_principale using company.naf_section (1-letter)
    if @search_params[:section_activite_principale].present? && @search_params[:section_activite_principale].is_a?(Array) # rubocop:disable Layout/LineLength
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

    # Filter by minimum effectif
    if @search_params[:effectif_min].present?
      effectif_min = @search_params[:effectif_min].to_i
      # Use EXISTS subquery to avoid materializing sirens in Ruby
      companies = companies.where(
        "EXISTS (
          SELECT 1 FROM osf_ent_effectifs oee
          WHERE oee.siren = companies.siren
          AND oee.is_latest = true
          AND oee.effectif >= ?
        )", effectif_min
      )
    end

    # Filter by minimum score
    if @search_params[:score_min].present?
      score_min = @search_params[:score_min].to_f
      # Use EXISTS subquery to avoid materializing sirens in Ruby
      companies = companies.where(
        "EXISTS (
          SELECT 1 FROM company_score_entries cse
          WHERE cse.siren = companies.siren
          AND cse.list_name = ?
          AND cse.score >= ?
        )", @list.label, score_min
      )
    end

    # Filter by minimum dette sociale
    if @search_params[:dette_sociale_min].present?
      dette_min = @search_params[:dette_sociale_min].to_f
      # Use EXISTS with aggregated subquery to avoid materializing sirens in Ruby
      # Sum dette sociale across ALL establishments of each company, using latest (`is_last`) OSF debit rows
      companies = companies.where(
        "EXISTS (
          SELECT 1 FROM establishments e
          INNER JOIN osf_debits od ON od.siret = e.siret
          WHERE e.siren = companies.siren
          AND od.is_last = true
          GROUP BY e.siren
          HAVING SUM(COALESCE(od.part_ouvriere, 0) + COALESCE(od.part_patronale, 0)) >= ?
        )", dette_min
      )
    end

    # Filter by libelle_procol (using procol_at_date function)
    if @search_params[:libelle_procol].present? && @search_params[:libelle_procol] != ""
      libelle_value = @search_params[:libelle_procol]
      current_date = Date.current

      # Use EXISTS subquery with procol_at_date function to avoid materializing sirens in Ruby
      companies = companies.where(
        "EXISTS (
          SELECT 1 FROM procol_at_date(?) AS procol
          WHERE procol.siren = companies.siren
          AND procol.libelle_procol = ?
        )", current_date, libelle_value
      )
    end

    # Filter by frequence_alerte (placeholder)
    if @search_params[:frequence_alerte].present? && @search_params[:frequence_alerte] != ""
      # TODO: Implement when logic is defined
    end

    # Filter by niveau_alerte (alert from CompanyScoreEntry)
    if @search_params[:niveau_alerte].present? && @search_params[:niveau_alerte] != ""
      alert_value = @search_params[:niveau_alerte]
      # Use EXISTS subquery to avoid materializing sirens in Ruby
      companies = companies.where(
        "EXISTS (
          SELECT 1 FROM company_score_entries cse
          WHERE cse.siren = companies.siren
          AND cse.list_name = ?
          AND cse.alert = ?
        )", @list.label, alert_value
      )
    end

    # Filter by premieres_alertes (first time appearing in CompanyScoreEntry)
    if @search_params[:premieres_alertes].present? && @search_params[:premieres_alertes] == "1"
      # A company is a "première alerte" if it ONLY appears in the current list
      # Use NOT EXISTS to avoid materializing sirens in Ruby
      # Since the base query already filters to companies in the current list,
      # we just need to ensure they don't appear in any other list
      companies = companies.where(
        "NOT EXISTS (
          SELECT 1 FROM company_score_entries cse
          WHERE cse.siren = companies.siren
          AND cse.list_name != ?
        )", @list.label
      )
    end

    # Filter by sans_entreprises_recentes (exclude companies created within last 3 years)
    if @search_params[:sans_entreprises_recentes].present? && @search_params[:sans_entreprises_recentes] == "1"
      three_years_ago = Date.current - 3.years
      # Exclude companies created within last 3 years, but include companies with NULL creation date
      companies = companies.where("creation IS NULL OR creation < ?", three_years_ago)
    end

    # Filter by sans_delai_urssaf (exclude companies with establishments having OsfDelai date_echeance > list_date)
    if @search_params[:sans_delai_urssaf].present? && @search_params[:sans_delai_urssaf] == "1" && @list.list_date.present? # rubocop:disable Layout/LineLength
      # Use NOT EXISTS subquery to avoid materializing sirens/sirets in Ruby
      # Exclude companies that have at least one establishment with OsfDelai where date_echeance > list_date
      companies = companies.where(
        "NOT EXISTS (
          SELECT 1 FROM establishments e
          INNER JOIN osf_delais od ON od.siret = e.siret
          WHERE e.siren = companies.siren
          AND od.date_echeance > ?
        )", @list.list_date
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

  def enrich_results_with_tracking_status(results) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Metrics/CyclomaticComplexity
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

  def enrich_results_with_alert_levels(results) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Metrics/CyclomaticComplexity
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
      end
    end
  end

  def enrich_results_with_first_alert_flag(results) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    return if results.blank?

    sirens = results.pluck("siren").compact.uniq
    return if sirens.blank?

    # A company is a "première alerte" if it ONLY appears in the current list
    sirens_in_other_lists = CompanyScoreEntry
                            .where(siren: sirens)
                            .where.not(list_name: @list.label)
                            .distinct
                            .pluck(:siren)
                            .to_set

    first_time_sirens = sirens.to_set - sirens_in_other_lists

    results.each do |result|
      result["is_first_alert"] = first_time_sirens.include?(result["siren"])
    end
  end

  def calculate_alert_breakdown(companies_query) # rubocop:disable Metrics/MethodLength
    # Use a single aggregated query with conditional aggregation to count both alert types
    # This avoids materializing all SIRENs in Ruby and reduces from 3 queries to 1
    counts = CompanyScoreEntry
             .where(list_name: @list.label)
             .where(siren: companies_query.select(:siren))
             .where(alert: ["Alerte seuil F1", "Alerte seuil F2"])
             .pick(
               Arel.sql("COUNT(DISTINCT CASE WHEN alert = 'Alerte seuil F1' THEN siren END)"),
               Arel.sql("COUNT(DISTINCT CASE WHEN alert = 'Alerte seuil F2' THEN siren END)")
             ) || [0, 0]

    {
      alerte_elevee: counts[0].to_i,
      alerte_moderee: counts[1].to_i
    }
  end

  def enrich_single_company(siren) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Metrics/CyclomaticComplexity
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
      end
    end

    # Get first alert flag
    sirens_in_other_lists = CompanyScoreEntry
                            .where(siren: siren)
                            .where.not(list_name: @list.label)
                            .exists?

    enrichment[:is_first_alert] = !sirens_in_other_lists

    # Get establishment count
    enrichment[:nombre_etablissements_ouverts] = Establishment
                                                 .where(siren: siren, is_active: true)
                                                 .count

    # Get procol status
    enrichment[:procol_status] = procol_status_for_siren(siren)

    enrichment
  end
end
