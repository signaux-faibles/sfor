module EstablishmentTrackingsHelper
  def next_sort_url(params)
    # Current direction.
    current_sort = params.dig(:q, :s)
    # Find next sort direction : asc or desc.
    next_direction = current_sort == "modified_at desc" ? "asc" : "desc"
    # Build next url : except view and toto (switch between table and cards view).
    sort_q = (params[:q]&.permit!&.to_h || {}).merge("s" => "modified_at #{next_direction}").except("view", "toto")
    establishment_trackings_path(q: sort_q)
  end

  def sort_icon_class(params)
    params.dig(:q, :s) == "modified_at asc" ? "fr-icon-arrow-up-s-fill" : "fr-icon-arrow-down-s-fill"
  end
end
