module ListExportTrackable
  extend ActiveSupport::Concern

  private

  def track_list_export(list, search_params, results_count) # rubocop:disable Metrics/MethodLength
    return unless current_user

    filters_hash = normalize_filters(search_params)

    Rails.logger.info("Filters hash: #{filters_hash}")
    Rails.logger.info("Results count: #{results_count}")

    Rails.logger.info("=================")

    Rails.logger.info(ListExportLog.already_exported_today?(
                        user_email: current_user.email,
                        list_name: list.label,
                        filters_hash: filters_hash
                      ))

    Rails.logger.info("=================")

    # Skip if already exported today with same filters
    return if ListExportLog.already_exported_today?(
      user_email: current_user.email,
      list_name: list.label,
      filters_hash: filters_hash
    )

    ListExportLog.create!(
      exported_at: Time.current,
      user_email: current_user.email,
      user_geo_zone: current_user.geo_access.name,
      user_segment: current_user.segment.name,
      list_name: list.label,
      active_filters: filters_hash,
      results_count: results_count
    )
  rescue StandardError => e
    Rails.logger.error("Error tracking list export: #{e}")
    Sentry.capture_exception(e, extra: {
                               user_email: current_user&.email,
                               list_name: list&.label
                             })
  end

  def normalize_filters(search_params)
    return nil if search_params.blank?

    # Remove pagination and UI-only params, keep only actual filters
    filter_keys = %w[
      q effectif_min score_min dette_sociale_min libelle_procol
      frequence_alerte niveau_alerte premieres_alertes sans_entreprises_recentes
      sans_delai_urssaf liste_retraitee departement_in forme_juridique
      section_activite_principale
    ]

    filters = search_params.to_h.slice(*filter_keys).compact_blank

    return nil if filters.blank?

    # Sort array values and sort keys for consistent JSON comparison
    normalized = filters.transform_values do |value|
      value.is_a?(Array) ? value.sort : value
    end

    # Sort by keys to ensure consistent JSON output
    normalized.sort.to_h.to_json
  end
end
