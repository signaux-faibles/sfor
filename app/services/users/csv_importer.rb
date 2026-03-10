require "csv"

module Users
  class CsvImporter # rubocop:disable Metrics/ClassLength
    Result = Struct.new(:created_users, :failed_rows, :mail_errors, :total_rows, keyword_init: true)

    def initialize(csv_content)
      @csv_content = csv_content
    end

    def call # rubocop:disable Metrics/MethodLength
      created_users = []
      failed_rows = []
      mail_errors = []
      total_rows = 0

      parse_csv.each_with_index do |row, index|
        total_rows += 1
        row_number = index + 2
        attributes = normalize_row(row)
        build_result = build_attributes(attributes)

        if build_result[:errors].any?
          failed_rows << failure_entry(row_number, attributes, build_result[:errors])
          next
        end

        user = User.new(build_result[:attributes])
        user.password = User.generate_admin_password

        if user.save
          begin
            user.send_reset_password_instructions
          rescue StandardError => e
            mail_errors << { email: user.email, error: e.message }
          end
          created_users << user
        else
          failed_rows << failure_entry(row_number, attributes, user.errors.full_messages)
        end
      end

      Result.new(created_users: created_users, failed_rows: failed_rows, mail_errors: mail_errors, total_rows: total_rows)
    end

    private

    def parse_csv
      csv = CSV.parse(@csv_content, headers: true)
      return csv if csv.headers.compact.size > 1 || csv.headers.first.nil?

      csv.headers.first.include?(";") ? CSV.parse(@csv_content, headers: true, col_sep: ";") : csv
    end

    def normalize_row(row)
      row.to_h.transform_keys { |key| force_utf8(key.to_s).strip }
         .transform_values do |value|
           value.is_a?(String) ? force_utf8(value).strip : value
         end
    end

    def build_attributes(attributes) # rubocop:disable Metrics/MethodLength
      errors = []

      email = attributes["email"]
      if email.blank?
        errors << "Email manquant"
      elsif User.exists?(email: email)
        errors << "Email déjà existant"
      end

      segment = find_by_name(Segment, attributes["segment_name"], "segment")
      geo_access = find_by_name(GeoAccess, attributes["geo_access"], "accès géographique")
      entity = find_by_name(Entity, attributes["entity"], "entité")

      errors.concat(segment[:errors])
      errors.concat(geo_access[:errors])
      errors.concat(entity[:errors])

      last_contact = parse_date(attributes["last_contact"])
      errors << "Date de dernier contact invalide" if attributes["last_contact"].present? && last_contact.nil?

      {
        attributes: {
          email: email,
          first_name: attributes["first_name"].presence,
          last_name: attributes["last_name"].presence,
          segment_id: segment[:record]&.id,
          geo_access_id: geo_access[:record]&.id,
          entity_id: entity[:record]&.id,
          description: attributes["description"].presence,
          ambassador: parse_boolean(attributes["ambassador"]),
          trained: parse_boolean(attributes["trained"]),
          feedbacks: attributes["feedbacks"].presence,
          last_contact: last_contact,
          level: "A"
        },
        errors: errors
      }
    end

    def find_by_name(model, name, label)
      return { record: nil, errors: ["#{label.capitalize} manquante"] } if name.blank?

      record = model.where("lower(name) = ?", name.downcase).first
      return { record: record, errors: [] } if record

      { record: nil, errors: ["#{label.capitalize} inconnue : #{name}"] }
    end

    def parse_boolean(value)
      return false if value.blank?

      normalized = value.to_s.strip.downcase
      %w[oui yes true 1].include?(normalized)
    end

    def parse_date(value)
      return nil if value.blank?

      Date.parse(value)
    rescue Date::Error, ArgumentError # rubocop:disable Lint/ShadowedException
      nil
    end

    def force_utf8(value)
      value.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
    end

    def failure_entry(row_number, attributes, errors)
      {
        row_number: row_number,
        email: attributes["email"],
        errors: errors,
        data: attributes
      }
    end
  end
end
