class ListsController < ApplicationController # rubocop:disable Metrics/ClassLength
  include SirenSiretRedirectable
  def index
    @lists = List.order(label: :asc)
  end

  def show # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
    @list = List.find(params[:id])

    # Get search params
    @search_params = params.require(:search).permit(:q, :section_activite_principale,
                                                    :ca_min, :forme_juridique,
                                                    :effectif_min, :score_min, :dette_sociale_min,
                                                    :stade_procol, :frequence_alerte, :niveau_alerte,
                                                    :page, :per_page, :cp_dep,
                                                    :cp_dep_type, :cp_dep_label) if params[:search].present?
    @search_params ||= {}

    # Check if search query is a valid SIREN or SIRET and redirect if so
    redirect_if_siren_or_siret(@search_params[:q])

    @page = @search_params[:page].to_i
    @page = 1 if @page < 1
    @per_page = @search_params[:per_page].to_i
    @per_page = 10 if @per_page < 1

    # Start with companies in this list (from company_score_entries)
    list_sirens = @list.company_score_entries.select(:siren).distinct.pluck(:siren).to_set

    # Step 1: Apply API filters if present
    api_filtered_sirens = apply_api_filters(list_sirens)

    Rails.logger.debug { "list_sirens: #{list_sirens.inspect}" }
    Rails.logger.debug { "api_filtered_sirens: #{api_filtered_sirens.inspect}" }

    # Step 2: Intersect with list companies
    filtered_sirens = list_sirens & api_filtered_sirens

    # Step 3: Get companies and apply database filters
    @companies = Company.where(siren: filtered_sirens.to_a)
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
    # Get sirens from company_score_entries, then query companies
    list_sirens = @list.company_score_entries.select(:siren).distinct.pluck(:siren)
    @companies = Company.where(siren: list_sirens).includes(:establishments).page(1).per(@per_page)
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

  def apply_api_filters(list_sirens) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
    # Check if we have any API filters
    has_api_filters = @search_params[:q].present? ||
                      @search_params[:section_activite_principale].present? ||
                      @search_params[:ca_min].present? ||
                      @search_params[:forme_juridique].present? ||
                      @search_params[:cp_dep].present?

    # If no API filters, return all list sirens
    return list_sirens unless has_api_filters

    # Build API service params
    # Note: API only accepts per_page between 1 and 25 (default 10)
    service_params = {
      page: 1,
      per_page: 25 # API maximum is 25
    }

    # Add query if present
    service_params[:q] = @search_params[:q] if @search_params[:q].present?

    # Add activity sector
    service_params[:activite_principale] =
      @search_params[:section_activite_principale] if @search_params[:section_activite_principale].present?

    # Add CA min
    service_params[:ca_min] = @search_params[:ca_min] if @search_params[:ca_min].present?

    # Add forme juridique
    service_params[:forme_juridique] = @search_params[:forme_juridique] if @search_params[:forme_juridique].present?

    # Add geo location
    if @search_params[:cp_dep].present? && @search_params[:cp_dep_type].present?
      case @search_params[:cp_dep_type]
      when "dep"
        service_params[:departement] = @search_params[:cp_dep]
      when "reg"
        service_params[:region] = @search_params[:cp_dep]
      when "cp"
        service_params[:code_postal] = @search_params[:cp_dep]
      when "epci"
        service_params[:epci] = @search_params[:cp_dep]
      when "insee"
        service_params[:code_commune] = @search_params[:cp_dep]
      end
    end

    # Call API and collect all results (handle pagination)
    api_sirens = Set.new
    page = 1
    max_pages = 10 # Limit to prevent infinite loops

    loop do
      service_params[:page] = page
      service = Api::RechercheEntreprisesApiService.new(service_params)
      response = service.search_company

      if service.errors.any? || response.nil?
        Rails.logger.error "API search errors: #{service.errors.join(', ')}"
        break
      end

      results = response["results"] || []
      break if results.empty?

      # Extract sirens and intersect with list immediately
      page_sirens = results.pluck("siren").compact.to_set
      api_sirens.merge(page_sirens & list_sirens)

      # Check if we have more pages
      total_pages = response["total_pages"] || 1
      break if page >= total_pages || page >= max_pages

      page += 1
    end

    api_sirens
  end

  def apply_database_filters(companies) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    company_sirens = companies.pluck(:siren)

    # Filter by minimum effectif
    if @search_params[:effectif_min].present?
      effectif_min = @search_params[:effectif_min].to_i
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
      company_sirens = companies.pluck(:siren)
    end

    # Filter by minimum score
    if @search_params[:score_min].present?
      score_min = @search_params[:score_min].to_f
      sirens_with_score = CompanyScoreEntry
                          .where(list_name: @list.label, siren: company_sirens)
                          .where(score: score_min..)
                          .distinct
                          .pluck(:siren)
                          .to_set

      companies = companies.where(siren: sirens_with_score.to_a)
      company_sirens = companies.pluck(:siren)
    end

    # Filter by minimum dette sociale
    if @search_params[:dette_sociale_min].present?
      dette_min = @search_params[:dette_sociale_min].to_f

      # Get all sirets for these companies
      company_sirets = Establishment.where(siren: company_sirens).pluck(:siret)

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

      # Get sirens from these sirets
      sirens_with_dette = Establishment
                          .where(siret: sirets_with_dette)
                          .pluck(:siren)
                          .to_set

      companies = companies.where(siren: sirens_with_dette.to_a)
    end

    # Filter by stade_procol (placeholder - model doesn't exist yet)
    if @search_params[:stade_procol].present? && @search_params[:stade_procol] != ""
      # TODO: Implement when OsfProcol model is created
      # For now, this is a placeholder
    end

    # Filter by frequence_alerte (placeholder)
    if @search_params[:frequence_alerte].present? && @search_params[:frequence_alerte] != ""
      # TODO: Implement when logic is defined
    end

    # Filter by niveau_alerte (placeholder)
    if @search_params[:niveau_alerte].present? && @search_params[:niveau_alerte] != ""
      # TODO: Implement when logic is defined
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
