module Companies
  class WaterfallChartBuilder
    def initialize(entry)
      @entry = entry
    end

    def build # rubocop:disable Metrics/MethodLength
      key_mapping = waterfall_key_mapping
      data_ordered = waterfall_data_from_entry(key_mapping)
      label_by_key = label_by_key_map(key_mapping)

      labels = []
      values = []
      risk = 0
      val1 = 0

      data_ordered.each do |key, value|
        risk += value
        val2 = (val1 + value).round(0)
        labels << label_by_key[key] if label_by_key[key]
        values << [val1.round(0), val2]
        val1 = val2
      end

      final_score = (@entry.score&.to_f || risk).round(0)
      values << [0, final_score]
      labels << "Risque de défaillance (%)"

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
      data = {}
      macro_expl = @entry.macro_expl || {}

      macro_expl.each do |macro_key, value|
        mapping = key_mapping[macro_key]
        next unless mapping

        data[mapping[:key]] = value.to_f.round(1)
      end

      data.sort_by { |_key, value| value }.reverse.to_h
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
