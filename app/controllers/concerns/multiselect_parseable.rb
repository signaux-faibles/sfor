module MultiselectParseable
  extend ActiveSupport::Concern

  # Converts multiselect component params into plain value arrays usable by Rails and ransack.
  def parse_multiselect(namespace, keys)
    ns_params = params[namespace]
    return if ns_params.blank?

    # Normalize keys into a { "json_key" => target_key } hash in both cases
    mappings = keys.is_a?(Hash) ? keys : keys.index_by { |k| "#{k}_values" }

    mappings.each do |json_key, target_key|
      json_val = ns_params[json_key]

      unless json_val.blank?
        begin
          values = JSON.parse(json_val)
          # Extract only the "value" field from each object and remove blanks
          ns_params[target_key] = values.map { |v| v["value"] }.compact_blank if values.is_a?(Array)
        rescue JSON::ParserError => e
          Rails.logger.debug { "Multiselect JSON ignored (#{namespace}.#{json_key}): #{e.message}" }
        end
      end

      cleanup_multiselect_transport_params!(ns_params, json_key)
    end
  end

  private

  # Removes Stimulus multiselect transport fields so strong params do not log unpermitted keys.
  def cleanup_multiselect_transport_params!(ns_params, json_key)
    if json_key.end_with?("_values")
      input_key = "#{json_key.delete_suffix('_values')}_input"
      ns_params.delete(input_key) if ns_params.key?(input_key)
    end

    ns_params.delete(json_key)
  end
end
