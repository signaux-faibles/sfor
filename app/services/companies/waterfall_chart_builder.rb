# frozen_string_literal: true

module Companies
  class WaterfallChartBuilder
    CONTRIBUTION_THRESHOLD = 0.05

    def initialize(entry)
      @entry = entry
    end

    def build
      key_mapping = waterfall_key_mapping
      data_ordered = waterfall_data_from_entry(key_mapping)
      label_by_key = label_by_key_map(key_mapping)

      labels = []
      values = []
      val1 = 0.0

      data_ordered.each do |key, value|
        val2 = val1 + value
        labels << label_by_key[key] if label_by_key[key]
        values << [val1, val2]
        val1 = val2
      end

      {
        labels: labels,
        values: values,
        seuils: waterfall_thresholds
      }
    end

    private

    def waterfall_key_mapping
      {
        "Dettes-sociales" => { key: "dettes_sociales", label: "Dettes sociales" },
        "Données-financières" => { key: "sante_financiere", label: "Santé financière" },
        "Recours-à-l'activité-partielle" => { key: "ap", label: "Recours à l'activité partielle" },
        "Variation-de-l'effectif-de-l'entreprise" => { key: "effectif", label: "Variation de l'effectif de l'entreprise" }
      }
    end

    def waterfall_data_from_entry(key_mapping)
      score = @entry.score.to_f
      macro_expl = @entry.macro_expl || {}

      raw_contributions = macro_expl.each_with_object({}) do |(macro_key, shap_risk), data|
        mapping = key_mapping[macro_key]
        next unless mapping

        data[mapping[:key]] = score - shap_risk.to_f
      end

      filtered_sum = raw_contributions.values.sum { |contribution| filtered_contribution(contribution) }
      return {} if filtered_sum <= 0

      raw_contributions
        .transform_values { |contribution| filtered_contribution(contribution) }
        .sort_by { |_key, value| value }
        .reverse
        .to_h
    end

    def filtered_contribution(contribution)
      contribution > CONTRIBUTION_THRESHOLD ? contribution : 0.0
    end

    def label_by_key_map(key_mapping)
      key_mapping.each_with_object({}) do |(_macro_key, mapping), acc|
        acc[mapping[:key]] = mapping[:label]
      end
    end

    def waterfall_thresholds
      seuil_f2 = ENV.fetch("SEUIL_F2", "65").to_f
      seuil_f1 = ENV.fetch("SEUIL_F1", "88").to_f
      [seuil_f2, seuil_f1]
    end
  end
end
