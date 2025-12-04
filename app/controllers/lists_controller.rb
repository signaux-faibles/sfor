class ListsController < ApplicationController # rubocop:disable Metrics/ClassLength
  include SirenSiretRedirectable
  def index
    @lists = List.order(label: :asc)
  end

  def show # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
    @list = List.find(params[:id])

    # Get search params
    @search_params = params.require(:search).permit(:q, :ca_min,
                                                    :effectif_min, :score_min,
                                                    :dette_sociale_min, :action_procol,
                                                    :frequence_alerte, :niveau_alerte,
                                                    :premieres_alertes, :sans_entreprises_recentes,
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

    # Apply all database filters
    @companies = apply_database_filters(@companies)

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
  rescue ActiveRecord::RecordNotFound
    redirect_to lists_path, alert: "Liste introuvable" # rubocop:disable Rails/I18nLocaleTexts
  rescue ActionController::ParameterMissing
    @search_params = {}
    # Get companies from company_score_entries
    @companies = Company.joins(:company_score_entries)
                        .where(company_score_entries: { list_name: @list.label })
                        .distinct
                        .includes(:establishments)
                        .page(1)
                        .per(@per_page)
    @results = @companies.map do |company|
      {
        "siren" => company.siren,
        "nom_complet" => company.raison_sociale || company.siren,
        "nombre_etablissements_ouverts" => company.establishments.size
      }
    end
    @pagination = {
      page: 1,
      per_page: @per_page,
      total_pages: @companies.total_pages,
      total_results: @companies.total_count
    }
    enrich_results_with_tracking_status(@results)
  end

  private

  def apply_database_filters(companies) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    # NOTE: All filters below are combined (AND logic) - each filter narrows down the results
    # from the previous filters. The `companies` query is progressively refined.

    # Systematically exclude companies with excluded NAF codes
    excluded_naf_codes = %w[
      8411Z 8412Z 8421Z 8422Z 8423Z 8424Z 8425Z 8413Z 8430A 8430B 8430C
      9491Z 9492Z 9420Z 9411Z 9412Z
      6411Z 6419Z 6430Z 6491Z 6492Z 6499Z 6511Z 6512Z 6520Z 6530Z 6611Z 6612Z 6619A 6619B 6621Z 6622Z 6629Z 6630Z
      8510Z 8520Z 8531Z 8532Z 8541Z 8542Z
      9900Z
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

    # Filter by section_activite_principale (first character of NAF code)
    if @search_params[:section_activite_principale].present? && @search_params[:section_activite_principale].is_a?(Array) # rubocop:disable Layout/LineLength
      sections = @search_params[:section_activite_principale].compact_blank
      if sections.any?
        # Build conditions for multiple sections (OR logic within sections)
        matching_sirens = Set.new

        sections.each do |section|
          # Filter by siege establishments with matching code_activite first character
          sirens_by_establishment = Establishment
                                    .where(siege: true)
                                    .where("code_activite LIKE ?", "#{section}%")
                                    .where.not(code_activite: nil)
                                    .distinct
                                    .pluck(:siren)
                                    .to_set

          matching_sirens.merge(sirens_by_establishment)
        end

        companies = companies.where(siren: matching_sirens.to_a)
      end
    end

    # Filter by forme_juridique (statut_juridique)
    if @search_params[:forme_juridique].present? && @search_params[:forme_juridique].is_a?(Array)
      statut_codes = @search_params[:forme_juridique].compact_blank
      companies = companies.where(statut_juridique: statut_codes) if statut_codes.any?
    end

    # Filter by department (siege establishment)
    if @search_params[:departement_in].present? && @search_params[:departement_in].is_a?(Array)
      department_codes = @search_params[:departement_in].compact_blank
      if department_codes.any?
        # Filter by companies whose siege establishment is in the selected departments
        matching_sirens = Establishment
                          .where(siege: true, departement: department_codes)
                          .distinct
                          .pluck(:siren)
                          .to_set
        companies = companies.where(siren: matching_sirens.to_a)
      end
    end

    # NOTE: ca_min (revenue) filter is not available in database
    # The form field remains but filtering is skipped
    if @search_params[:ca_min].present?
      Rails.logger.warn "CA min filter requested but revenue data not available in database"
    end

    # Filter by minimum effectif
    if @search_params[:effectif_min].present?
      effectif_min = @search_params[:effectif_min].to_i
      # Get current company sirens from the filtered companies query
      company_sirens = companies.pluck(:siren)

      # Get the latest effectif for each siren
      latest_effectifs = OsfEntEffectif
                         .where(siren: company_sirens)
                         .group(:siren)
                         .maximum(:periode)

      # Filter sirens where latest effectif >= min
      sirens_with_effectif = latest_effectifs.select do |siren, _periode|
        latest = OsfEntEffectif.where(siren: siren, periode: latest_effectifs[siren]).first
        latest&.effectif.to_i >= effectif_min
      end.keys.to_set

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
      # Get current company sirens from the filtered companies query
      company_sirens = companies.pluck(:siren)

      # Get all sirets for these companies (only siege establishments)
      company_sirets = Establishment.where(siren: company_sirens, siege: true).pluck(:siret)

      # Get latest periode for each siret
      latest_periodes = OsfDebit
                        .where(siret: company_sirets)
                        .group(:siret)
                        .maximum(:periode)

      # Calculate total dette for each siret at latest periode
      sirets_with_dette = latest_periodes.select do |siret, _periode|
        debit = OsfDebit.where(siret: siret, periode: latest_periodes[siret]).first
        total_dette = (debit&.part_ouvriere.to_f + debit&.part_patronale.to_f)
        total_dette >= dette_min
      end.keys

      # Get sirens from these sirets (only from siege establishments)
      sirens_with_dette = Establishment
                          .where(siret: sirets_with_dette, siege: true)
                          .pluck(:siren)
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
end
