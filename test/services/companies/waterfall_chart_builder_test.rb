# frozen_string_literal: true

require "test_helper"

module Companies
  class WaterfallChartBuilderTest < ActiveSupport::TestCase
    setup do
      @entry = company_score_entries(:one_paris_list_test_2025)
      @entry.update!(
        score: 75.0,
        macro_expl: {
          "Dettes-sociales" => 70.0,
          "Données-financières" => 74.0,
          "Recours-à-l'activité-partielle" => 75.0,
          "Variation-de-l'effectif-de-l'entreprise" => 60.0
        }
      )
    end

    test "builds cumulative bars from filtered Shapley contributions" do
      data = WaterfallChartBuilder.new(@entry).build

      assert_equal [
        "Variation de l'effectif de l'entreprise",
        "Dettes sociales",
        "Santé financière",
        "Recours à l'activité partielle"
      ], data[:labels]

      assert_equal [[0.0, 15.0], [15.0, 20.0], [20.0, 21.0], [21.0, 21.0]], data[:values]
    end

    test "returns empty chart when no contribution passes threshold" do
      @entry.update!(
        score: 75.0,
        macro_expl: {
          "Dettes-sociales" => 74.96,
          "Données-financières" => 75.0,
          "Recours-à-l'activité-partielle" => 75.0,
          "Variation-de-l'effectif-de-l'entreprise" => 75.0
        }
      )

      data = WaterfallChartBuilder.new(@entry).build

      assert_empty data[:labels]
      assert_empty data[:values]
    end

    test "returns empty chart when macro_expl is missing" do
      @entry.update!(macro_expl: nil)

      data = WaterfallChartBuilder.new(@entry).build

      assert_empty data[:labels]
      assert_empty data[:values]
    end
  end
end
