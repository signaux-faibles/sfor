class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:unauthorized]

  def home; end

  def search # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
    @search_params = params.require(:search).permit(:q, :tranche_effectif_salarie, :section_activite_principale,
                                                    :page, :per_page, :cp_dep, :cp_dep_type, :cp_dep_label)
    @page = @search_params[:page].to_i
    @page = 1 if @page < 1
    @per_page = @search_params[:per_page].to_i
    @per_page = 10 if @per_page < 1

    @results = nil
    @pagination = {}

    return if @search_params[:q].blank?

    # Map geo location parameters to API format
    service_params = @search_params.except(:cp_dep, :cp_dep_type, :cp_dep_label).merge(
      page: @page,
      per_page: @per_page
    )

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
end
