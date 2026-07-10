# frozen_string_literal: true

# Handles filtering and index functionality for establishment trackings
module EstablishmentTrackings::Filterable
  extend ActiveSupport::Concern
  include MultiselectParseable

  private

  def parse_multiselect_q_params
    parse_multiselect(:q, {
                        "establishment_departement_in_values" => :establishment_departement_in,
                        "state_in_values" => :state_in,
                        "tracking_labels_id_in_values" => :tracking_labels_id_in,
                        "supporting_services_id_in_values" => :supporting_services_id_in,
                        "sectors_id_in_values" => :sectors_id_in
                      })
  end

  def handle_filters(params)
    if params[:clear_filters]
      session[:establishment_tracking_filters] = nil
      redirect_to action: :index and {}
    elsif params[:q].present?
      session[:establishment_tracking_filters] = params[:q].except(:filters_open)
      params[:q]
    else
      (session[:establishment_tracking_filters] || {}).except("filters_open", :filters_open)
    end
  end

  def handle_view_params(params)
    @current_view = params.dig(:q, :view) || "table"
    params[:q]&.except(:view)
  end

  def determine_base_scope
    if params.dig(:q, :my_tracking) == "1"
      EstablishmentTracking.kept
    else
      policy_scope(EstablishmentTracking).kept
    end
  end

  def apply_filters(base_scope, clean_params)
    @filter_params = clean_params || {}
    @q = base_scope.ransack(clean_params)
    filter_by_tracking_type(@q.result)
  end

  def filter_by_tracking_type(result)
    case params.dig(:q, :my_tracking)
    when "1"
      user_tracking_ids = EstablishmentTracking.kept.with_user_as_referent_or_participant(current_user).select(:id)
      result.where(establishment_trackings: { id: user_tracking_ids }).distinct
    when "network"
      result.by_network(current_user.network_ids).distinct
    else
      result
    end
  end

  def paginate_trackings(trackings)
    trackings.includes(:referents, :criticality, establishment: { company: :size, department: [] })
             .page(params[:page])
             .per(15)
  end
end
