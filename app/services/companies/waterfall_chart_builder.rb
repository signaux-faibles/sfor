# frozen_string_literal: true

module Companies
  # Builds waterfall chart data from +macro_expl+ (Shapley contributions per variable group).
  #
  # +macro_expl+ stores Δp_j in [0, 1]. CompanyScoreEntry#score is not used here.
  # Algorithm (see data-science spec):
  #   1. Threshold: Δp'_j = 0 when Δp_j < seuil, else Δp'_j = Δp_j
  #   2. Normalize:  Δr_j = Δp'_j / Σ_k Δp'_k  (shares sum to 1)
  #   3. Keep only groups with Δr_j > 0 for display
  #   4. Chart bars: cumulative segments of Δr_j × 100 on the 0–100 % axis
  class WaterfallChartBuilder
    # Minimum Δp_j kept before normalization (same units as macro_expl, i.e. [0, 1]).
    CONTRIBUTION_THRESHOLD = 0.05

    # macro_expl is in [0, 1]; the chart Y axis is fixed to 0–100 %.
    DISPLAY_SCALE = 100.0

    def initialize(entry)
      @entry = entry
    end

    def build
      key_mapping = waterfall_key_mapping
      data_ordered = waterfall_data_from_entry(key_mapping)
      label_by_key = label_by_key_map(key_mapping)

      # Cumulative waterfall: each bar spans [previous_total, previous_total + segment_height].
      labels = []
      values = []
      val1 = 0.0

      data_ordered.each do |key, bar_height|
        val2 = val1 + bar_height
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
        "Autres" => { key: "autres", label: "Autres" },
        "Dettes-sociales" => { key: "dettes_sociales", label: "Dettes sociales" },
        "Données-financières" => { key: "sante_financiere", label: "Santé financière" },
        "Recours-à-l'activité-partielle" => { key: "ap", label: "Recours à l'activité partielle" },
        "Variation-de-l'effectif-de-l'entreprise" => { key: "effectif", label: "Variation de l'effectif de l'entreprise" }
      }
    end

    def waterfall_data_from_entry(key_mapping)
      macro_expl = @entry.macro_expl || {}

      # Step 1 — apply threshold per group (Δp_j → Δp'_j).
      thresholded = macro_expl.each_with_object({}) do |(macro_key, delta_p), data|
        mapping = key_mapping[macro_key]
        next unless mapping

        data[mapping[:key]] = thresholded_delta_p(delta_p.to_f)
      end

      filtered_sum = thresholded.values.sum
      return {} if filtered_sum <= 0

      # Steps 2 & 3 — normalize to shares (Δr_j), drop zero terms, sort largest first.
      # Step 4 — scale to % for the chart (Σ Δr_j × 100 = 100 when all groups are kept).
      thresholded
        .transform_values { |delta_p_prime| (delta_p_prime / filtered_sum) * DISPLAY_SCALE }
        .reject { |_key, delta_r| delta_r <= 0 }
        .sort_by { |_key, delta_r| delta_r }
        .reverse
        .to_h
    end

    # Step 1: Δp'_j = 0 if Δp_j < seuil, otherwise Δp'_j = Δp_j.
    def thresholded_delta_p(delta_p)
      delta_p < CONTRIBUTION_THRESHOLD ? 0.0 : delta_p
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
