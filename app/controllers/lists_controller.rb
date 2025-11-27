class ListsController < ApplicationController # rubocop:disable Metrics/ClassLength
  include SirenSiretRedirectable
  def index
    @lists = List.order(label: :asc)
  end

  def show # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
    @list = List.find(params[:id])

    # Get search params
    @search_params = params.require(:search).permit(:q, :section_activite_principale,
                                                    :ca_min,
                                                    :effectif_min, :score_min,
                                                    :dette_sociale_min, :stade_procol,
                                                    :frequence_alerte, :niveau_alerte,
                                                    :page, :per_page, departement_in: [],
                                                                      forme_juridique: []) if params[:search].present?
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
    # Filter by search query (q) - SIREN or raison sociale
    if @search_params[:q].present?
      query = @search_params[:q].strip
      companies = companies.where(
        "companies.siren ILIKE ? OR companies.raison_sociale ILIKE ?",
        "%#{query}%", "%#{query}%"
      )
    end

    # Filter by section_activite_principale (first character of NAF code)
    if @search_params[:section_activite_principale].present?
      section = @search_params[:section_activite_principale]
      # Filter by establishments with matching code_activite first character
      # or company_score_entries with matching code_naf first character
      sirens_by_establishment = Establishment
                                .where("code_activite LIKE ?", "#{section}%")
                                .where.not(code_activite: nil)
                                .distinct
                                .pluck(:siren)
                                .to_set

      sirens_by_score_entry = CompanyScoreEntry
                              .where(list_name: @list.label)
                              .where("code_naf LIKE ?", "#{section}%")
                              .where.not(code_naf: nil)
                              .distinct
                              .pluck(:siren)
                              .to_set

      # Combine both sources
      matching_sirens = sirens_by_establishment | sirens_by_score_entry
      companies = companies.where(siren: matching_sirens.to_a)
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
