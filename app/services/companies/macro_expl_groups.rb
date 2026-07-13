# frozen_string_literal: true

module Companies
  # Canonical mapping between macroExpl JSON keys, display labels, and company_lists columns.
  module MacroExplGroups
    Entry = Struct.new(:json_key, :internal_key, :label, :score_column, :legacy_json_keys, keyword_init: true) do
      def initialize(json_key:, internal_key:, label:, score_column:, legacy_json_keys: [])
        super
      end

      def json_keys
        [json_key, *legacy_json_keys]
      end
    end

    ALL = [
      Entry.new(json_key: "Age-de-l'entreprise", internal_key: "age", label: "Âge de l'entreprise",
                score_column: :score_age, legacy_json_keys: ["Autres"]),
      Entry.new(json_key: "Cluster-économique", internal_key: "cluster_economique", label: "Secteur d'activité",
                score_column: :score_cluster_economique),
      Entry.new(json_key: "Dettes-sociales", internal_key: "dettes_sociales", label: "Dettes sociales",
                score_column: :score_dettes),
      Entry.new(json_key: "Données-financières", internal_key: "sante_financiere", label: "Santé financière",
                score_column: :score_financier),
      Entry.new(json_key: "Recours-à-l'activité-partielle", internal_key: "ap",
                label: "Recours à l'activité partielle", score_column: :score_ap),
      Entry.new(json_key: "Variation-de-l'effectif-de-l'entreprise", internal_key: "effectif",
                label: "Effectif de l'entreprise", score_column: :score_effectif)
    ].freeze

    def self.waterfall_key_mapping
      ALL.each_with_object({}) do |entry, mapping|
        entry.json_keys.each do |json_key|
          mapping[json_key] = { key: entry.internal_key, label: entry.label }
        end
      end
    end

    # Prefer the canonical JSON key; fall back to legacy aliases for older lists.
    def self.normalize(macro_expl)
      data = (macro_expl || {}).stringify_keys

      ALL.each do |entry|
        entry.legacy_json_keys.each do |legacy_key|
          data[entry.json_key] = data[legacy_key] if data[entry.json_key].nil? && data.key?(legacy_key)
          data.delete(legacy_key)
        end
      end

      data
    end

    def self.macro_expl_value_sql(entry)
      json_keys = entry.json_keys.map { |key| sql_string_literal(key) }

      if json_keys.one?
        "ROUND((cse.macro_expl->>#{json_keys.first})::numeric)"
      else
        coalesce = json_keys.map { |literal| "(cse.macro_expl->>#{literal})::numeric" }.join(", ")
        "ROUND(COALESCE(#{coalesce}))"
      end
    end

    def self.score_columns
      ALL.map(&:score_column)
    end

    def self.sql_string_literal(value)
      ActiveRecord::Base.connection.quote(value)
    end
    private_class_method :sql_string_literal
  end
end
