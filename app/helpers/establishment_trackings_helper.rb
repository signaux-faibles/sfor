module EstablishmentTrackingsHelper
  # Public : Build url params for sorting.
  def next_sort_url(params)
    sort_q = current_q_params(params)
    sort_q["s"] = "modified_at #{next_sort_direction(params)}"
    establishment_trackings_path(q: sort_q)
  end

  # Public : Define sort icon class.
  def sort_icon_class(params)
    current_modified_at_direction(params) == "asc" ? "fr-icon-arrow-up-s-fill" : "fr-icon-arrow-down-s-fill"
  end

  private

  # Private : Define sort direction.
  def next_sort_direction(params)
    current_modified_at_direction(params) == "desc" ? "asc" : "desc"
  end

  # Private : Define current sort direction.
  def current_modified_at_direction(params)
    current_sort = current_q_params(params)["s"].to_s
    modified_at_sort = current_sort
                       .split(",")
                       .map(&:strip)
                       .find { |sort_value| sort_value.start_with?("modified_at ") }

    modified_at_sort&.split&.last
  end

  # Private : Get current query params.
  def current_q_params(params)
    if params[:q].respond_to?(:to_unsafe_h)
      params[:q].to_unsafe_h
    else
      params[:q].to_h
    end
  end
end
