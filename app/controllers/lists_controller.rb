class ListsController < ApplicationController # rubocop:disable Metrics/ClassLength
  include SirenSiretRedirectable
  def index
    @lists = List.order(label: :asc)
  end

  def show # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
    @list = List.find(params[:id])

    # Get search params
    @search_params = params.require(:search).permit(:q,
                                                    :effectif_min, :score_min,
                                                    :dette_sociale_min, :action_procol,
                                                    :frequence_alerte, :niveau_alerte,
                                                    :premieres_alertes, :sans_entreprises_recentes,
                                                    :liste_retraitee,
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

    # Calculate alert breakdown from filtered results (before pagination)
    @alert_breakdown = calculate_alert_breakdown(@companies)

    respond_to do |format|
      format.html do
        # Paginate
        @companies = @companies.includes(:establishments).page(@page).per(@per_page)

        # Format results for display
        @results = @companies.map do |company|
          {
            "siren" => company.siren,
            "nom_complet" => company.raison_sociale || company.siren,
            "nombre_etablissements_ouverts" => company.establishments.size
          }
        end

        @pagination = {
          page: @page,
          per_page: @per_page,
          total_pages: @companies.total_pages,
          total_results: @companies.total_count
        }

        # Enrich with tracking status
        enrich_results_with_tracking_status(@results)
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

    # Calculate alert breakdown from filtered results (before pagination)
    @alert_breakdown = calculate_alert_breakdown(@companies)

    respond_to do |format|
      format.html do
        # Paginate
        @companies = @companies.includes(:establishments).page(@page).per(@per_page)

        # Format results for display
        @results = @companies.map do |company|
          {
            "siren" => company.siren,
            "nom_complet" => company.raison_sociale || company.siren,
            "nombre_etablissements_ouverts" => company.establishments.size
          }
        end

        @pagination = {
          page: @page,
          per_page: @per_page,
          total_pages: @companies.total_pages,
          total_results: @companies.total_count
        }

        # Enrich with tracking status
        enrich_results_with_tracking_status(@results)
      end
      format.xlsx do
        export_list(@companies)
      end
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
      company_sirens = companies.pluck(:siren)

      sirens_with_effectif = OsfEntEffectif
                             .where(siren: company_sirens, is_latest: true)
                             .where(effectif: effectif_min..)
                             .distinct
                             .pluck(:siren)
                             .to_set

      companies = companies.where(siren: sirens_with_effectif.to_a)
    end

    # Filter by minimum score
    if @search_params[:score_min].present?
      score_min = @search_params[:score_min].to_f
      # Get current company sirens from the filtered companies query
      company_sirens = companies.pluck(:siren)

      sirens_with_score = CompanyScoreEntry
                          .where(list_name: @list.label, siren: company_sirens)
                          .where(score: score_min..)
                          .distinct
                          .pluck(:siren)
                          .to_set

      companies = companies.where(siren: sirens_with_score.to_a)
    end

    # Filter by minimum dette sociale
    if @search_params[:dette_sociale_min].present?
      dette_min = @search_params[:dette_sociale_min].to_f
      company_sirens = companies.pluck(:siren)

      # Sum dette sociale across ALL establishments of each company, using latest (`is_last`) OSF debit rows
      sirens_with_dette = OsfDebit
                          .joins(:establishment)
                          .where(is_last: true, establishments: { siren: company_sirens })
                          .group("establishments.siren")
                          .having(
                            "SUM(COALESCE(osf_debits.part_ouvriere, 0) + COALESCE(osf_debits.part_patronale, 0)) >= ?",
                            dette_min
                          )
                          .pluck("establishments.siren")
                          .to_set

      companies = companies.where(siren: sirens_with_dette.to_a)
    end

    # Filter by action_procol (using procol_at_date function)
    if @search_params[:action_procol].present? && @search_params[:action_procol] != ""
      action_value = @search_params[:action_procol]
      current_date = Date.current

      # Execute the function query first to get sirens, then filter companies
      # This ensures the subquery is evaluated before being used in the WHERE clause
      if action_value == "in_bonis"
        # Companies that are NOT in the procol_at_date results (no current action_procol = "In Bonis")
        sql = ActiveRecord::Base.sanitize_sql([
                                                "SELECT DISTINCT siren FROM procol_at_date(?) AS procol",
                                                current_date
                                              ])
        sirens_with_procol = ActiveRecord::Base.connection.execute(sql)
                                               .filter_map { |row| row["siren"] }
                                               .to_set

        # Filter for companies with no current action_procol
        companies = companies.where.not(siren: sirens_with_procol.to_a)
      else
        # Companies that ARE in the procol_at_date results with matching action_procol
        # Valid values: "sauvegarde", "redressement", "liquidation"
        sql = ActiveRecord::Base.sanitize_sql([
                                                "SELECT DISTINCT siren FROM procol_at_date(?) AS procol WHERE procol.action_procol = ?", # rubocop:disable Layout/LineLength
                                                current_date, action_value
                                              ])
        matching_sirens = ActiveRecord::Base.connection.execute(sql)
                                            .filter_map { |row| row["siren"] }
                                            .to_set

        # Filter companies to only those with matching action_procol
        companies = companies.where(siren: matching_sirens.to_a)
      end
    end

    # Filter by frequence_alerte (placeholder)
    if @search_params[:frequence_alerte].present? && @search_params[:frequence_alerte] != ""
      # TODO: Implement when logic is defined
    end

    # Filter by niveau_alerte (alert from CompanyScoreEntry)
    if @search_params[:niveau_alerte].present? && @search_params[:niveau_alerte] != ""
      alert_value = @search_params[:niveau_alerte]
      # Get current company sirens from the filtered companies query
      company_sirens = companies.pluck(:siren)

      # Filter companies by alert value in CompanyScoreEntry for this list
      sirens_with_alert = CompanyScoreEntry
                          .where(list_name: @list.label, siren: company_sirens, alert: alert_value)
                          .distinct
                          .pluck(:siren)
                          .to_set

      companies = companies.where(siren: sirens_with_alert.to_a)
    end

    # Filter by premieres_alertes (first time appearing in CompanyScoreEntry)
    if @search_params[:premieres_alertes].present? && @search_params[:premieres_alertes] == "1"
      # Get current company sirens from the filtered companies query
      company_sirens = companies.pluck(:siren)

      # A company is a "première alerte" if it ONLY appears in the current list
      # Find sirens that appear in other lists - these are NOT premières alertes
      sirens_in_other_lists = CompanyScoreEntry
                              .where(siren: company_sirens)
                              .where.not(list_name: @list.label)
                              .distinct
                              .pluck(:siren)
                              .to_set

      # Filter to only sirens that don't appear in other lists
      first_time_sirens = company_sirens.to_set - sirens_in_other_lists

      companies = companies.where(siren: first_time_sirens.to_a)
    end

    # Filter by sans_entreprises_recentes (exclude companies created within last 3 years)
    if @search_params[:sans_entreprises_recentes].present? && @search_params[:sans_entreprises_recentes] == "1"
      three_years_ago = Date.current - 3.years
      # Exclude companies created within last 3 years, but include companies with NULL creation date
      companies = companies.where("creation IS NULL OR creation < ?", three_years_ago)
    end

    # Filter by liste_retraitee (only show companies in SjcfCompany for this list)
    if @search_params[:liste_retraitee].present? && @search_params[:liste_retraitee] == "1"
      # Get current company sirens from the filtered companies query
      company_sirens = companies.pluck(:siren)

      # Get sirens that exist in SjcfCompany for this list
      sirens_in_sjcf = SjcfCompany
                       .where(libelle_liste: @list.label, siren: company_sirens)
                       .distinct
                       .pluck(:siren)
                       .to_set

      companies = companies.where(siren: sirens_in_sjcf.to_a)
    end

    companies
  end

  def enrich_results_with_tracking_status(results) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    return if results.blank?

    sirens = results.pluck("siren").compact.uniq
    return if sirens.blank?

    sirens_with_tracking = Establishment
                           .joins(:establishment_trackings)
                           .where(siren: sirens)
                           .merge(EstablishmentTracking.kept.in_progress)
                           .distinct
                           .pluck(:siren)
                           .to_set

    results.each do |result|
      result["has_tracking_in_progress"] = sirens_with_tracking.include?(result["siren"])
    end
  end

  def calculate_alert_breakdown(companies_query) # rubocop:disable Metrics/MethodLength
    # Get all sirens from the filtered companies query
    filtered_sirens = companies_query.pluck(:siren).to_set

    return { alerte_elevee: 0, alerte_moderee: 0 } if filtered_sirens.empty?

    # Count distinct sirens with each alert level in this list
    alerte_elevee_count = CompanyScoreEntry
                          .where(list_name: @list.label, siren: filtered_sirens.to_a, alert: "Alerte seuil F1")
                          .select(:siren)
                          .distinct
                          .count

    alerte_moderee_count = CompanyScoreEntry
                           .where(list_name: @list.label, siren: filtered_sirens.to_a, alert: "Alerte seuil F2")
                           .select(:siren)
                           .distinct
                           .count

    {
      alerte_elevee: alerte_elevee_count,
      alerte_moderee: alerte_moderee_count
    }
  end
end
