class PagesController < ApplicationController # rubocop:disable Metrics/ClassLength
  include SirenSiretRedirectable
  include ProcolStatusable
  include MultiselectParseable

  skip_before_action :authenticate_user!, only: [:unauthorized]
  before_action :set_secteurs_activite_options, only: %i[home search]

  def home; end

  def search # rubocop:disable Metrics/MethodLength
    parse_multiselect_params
    @search_params = params.require(:search).permit(:q, :tranche_effectif_salarie,
                                                    :page, :per_page, :cp_dep,
                                                    :cp_dep_type, :cp_dep_label,
                                                    section_activite_principale: []) if params[:search].present?
    @search_params ||= {}
    @selected_sections_json = Array(@search_params[:section_activite_principale]).compact_blank
                                                                                 .map { |v| @secteurs_activite_options.find { |s| s[:value] == v } }
                                                                                 .compact.to_json

    # Check if search query is a valid SIREN or SIRET and redirect if so
    redirect_if_siren_or_siret(@search_params[:q])

    @page = @search_params[:page].to_i
    @page = 1 if @page < 1
    @per_page = @search_params[:per_page].to_i
    @per_page = 10 if @per_page < 1

    @results = nil
    @pagination = {}

    # return if @search_params[:q].blank?

    # Map geo location parameters to API format
    service_params = @search_params.except(:cp_dep, :cp_dep_type, :cp_dep_label).merge(
      page: @page,
      per_page: @per_page
    )

    # Handle section_activite_principale: convert array to comma-separated string for API
    # If empty, default to all sections except O and U for API call (business request)
    # But keep @search_params empty so the form remains visually empty
    sections_array = Array(service_params[:section_activite_principale]).compact_blank
    service_params[:section_activite_principale] = if sections_array.empty?
                                                     # Default to all sections except O and U
                                                     "A,B,C,D,E,F,G,H,I,J,K,L,M,N,P,Q,R,S,T"
                                                   else
                                                     # Convert array to comma-separated string
                                                     sections_array.join(",")
                                                   end

    # Convert cp_dep_type and cp_dep to API parameters
    cp_dep = @search_params[:cp_dep]
    cp_dep_type = @search_params[:cp_dep_type]

    if cp_dep.present? && cp_dep_type.present?
      case cp_dep_type
      when "dep"
        service_params[:departement] = cp_dep
      when "reg"
        service_params[:region] = cp_dep
      when "cp"
        service_params[:code_postal] = cp_dep
      when "epci"
        service_params[:epci] = cp_dep
      when "insee"
        service_params[:code_commune] = cp_dep
      end
    end

    service = Api::RechercheEntreprisesApiService.new(service_params)
    response = service.search_company

    if service.errors.any?
      flash.now[:alert] = service.errors.join(", ")
      @results = []
      @pagination = {}
    elsif response
      @results = response["results"] || []
      enrich_results_with_tracking_status(@results)
      enrich_results_with_alert_levels(@results)
      enrich_results_with_procol_status(@results)
      @pagination = {
        page: response["page"] || @page,
        per_page: response["per_page"] || @per_page,
        total_pages: response["total_pages"] || 1,
        total_results: response["total_results"] || 0
      }
    end
  rescue ActionController::ParameterMissing
    @search_params = {}
    @results = []
    @pagination = {}
  end

  def unauthorized; end

  def accessibilite; end
  def support; end

  def not_found_redirect
    flash[:alert] = I18n.t("errors.page_not_found", default: "La page recherchée n'existe pas")
    redirect_to root_path
  end

  def establishment_trackings_not_found
    flash[:alert] = I18n.t("errors.page_not_found", default: "La page recherchée n'existe pas")
    redirect_to establishment_path(params[:siret])
  end

  private

  def enrich_results_with_tracking_status(results) # rubocop:disable Metrics/MethodLength
    return if results.blank?

    # Extract all sirens from results
    sirens = results.pluck("siren").compact.uniq
    return if sirens.blank?

    # Count trackings by state for each siren
    # Get all trackings for these establishments, grouped by siren and state
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

    # Get the last list
    last_list = List.order(code: :desc).first
    return unless last_list

    # Extract all sirens from results
    sirens = results.pluck("siren").compact.uniq
    return if sirens.blank?

    # Find all CompanyScoreEntry records for these sirens in the last list
    # Group by siren and take the most recent entry (by created_at) for each siren
    alert_entries = {}
    CompanyScoreEntry
      .where(siren: sirens, list_name: last_list.label)
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
      if alert
        case alert.downcase
        when "alerte seuil f1"
          result["alert_level"] = "elevee"
        when "alerte seuil f2"
          result["alert_level"] = "moderee"
        end
      end
    end
  end

  def parse_multiselect_params
    parse_multiselect(:search, %w[section_activite_principale])
  end

  def set_secteurs_activite_options
    @secteurs_activite_options = [
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
      { value: "P", label: "P - Enseignement" },
      { value: "Q", label: "Q - Santé humaine et action sociale" },
      { value: "R", label: "R - Arts, spectacles et activités récréatives" },
      { value: "S", label: "S - Autres activités de services" },
      { value: "T", label: "T - Activités des ménages en tant qu'employeurs ; activités indifférenciées des ménages en tant que producteurs de biens et services pour usage propre" }
    ]
    @selected_sections_json = [].to_json
  end
end
