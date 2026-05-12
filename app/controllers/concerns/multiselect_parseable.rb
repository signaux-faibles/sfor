module MultiselectParseable
  extend ActiveSupport::Concern

  # Converts multiselect component params into plain value arrays usable by Rails and ransack.
  def parse_multiselect(namespace, keys)
    ns_params = params[namespace]
    return unless ns_params.present?

    # Normalize keys into a { "json_key" => target_key } hash in both cases
    mappings = keys.is_a?(Hash) ? keys : keys.to_h { |k| ["#{k}_values", k] }

    mappings.each do |json_key, target_key|
      json_val = ns_params[json_key]
      next unless json_val.present?

      begin
        values = JSON.parse(json_val)
        # Extract only the "value" field from each object and remove blanks
        ns_params[target_key] = values.map { |v| v["value"] }.compact_blank if values.is_a?(Array)
      rescue JSON::ParserError
      end
    end
  end
end
