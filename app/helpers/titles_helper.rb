module TitlesHelper
  def search_page_title(search_params, pagination)
    query = search_params[:q]
    page = search_params[:page].to_i
    total_results = pagination[:total_results].to_i
    current_page = pagination[:page].to_i

    has_query = query.present?
    has_page = page > 1

    # No query or page, return default title
    return "Recherche" unless has_query || has_page

    # Start title.
    title = has_query ? "Recherche \"#{h(query)}\"".html_safe : "Recherche"

    # Add results count (if needed).
    results_label = case total_results
                    when 1 then "1 résultat trouvé"
                    when (2..) then "#{total_results} résultats trouvés"
                    else "aucun résultat trouvé"
                    end

    title += ", #{results_label}"

    # Add page number (if needed).
    title += ", page #{current_page}" if has_page

    title
  end
end
