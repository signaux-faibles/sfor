# frozen_string_literal: true

require "test_helper"

module Companies
  class WaterfallChartBuilderTest < ActiveSupport::TestCase
    setup do
      @entry = company_score_entries(:one_paris_list_test_2025)
    end

    test "builds normalized cumulative bars from macro_expl deltas" do
      @entry.update!(
        macro_expl: {
          "Dettes-sociales" => 0.2,
          "Données-financières" => 0.5,
          "Recours-à-l'activité-partielle" => 0.01,
          "Variation-de-l'effectif-de-l'entreprise" => 0.3
        }
      )

      data = WaterfallChartBuilder.new(@entry).build

      assert_equal ["Santé financière", "Variation de l'effectif de l'entreprise", "Dettes sociales"], data[:labels]
      assert_in_delta 50.0, data[:values][0][1] - data[:values][0][0], 0.01
      assert_in_delta 100.0, data[:values].last[1], 0.01
    end

    test "matches slide example with threshold 0.4" do
      @entry.update!(
        macro_expl: {
          "Dettes-sociales" => -0.2,
          "Variation-de-l'effectif-de-l'entreprise" => 0.5,
          "Données-financières" => 1.5,
          "Autres" => 0.3
        }
      )

      stub_const(WaterfallChartBuilder, :CONTRIBUTION_THRESHOLD, 0.4) do
        data = WaterfallChartBuilder.new(@entry).build

        assert_equal ["Santé financière", "Variation de l'effectif de l'entreprise"], data[:labels]
        assert_equal [[0.0, 75.0], [75.0, 100.0]], data[:values]
      end
    end

    test "returns empty chart when no delta passes threshold" do
      @entry.update!(
        macro_expl: {
          "Dettes-sociales" => 0.01,
          "Données-financières" => 0.02,
          "Autres" => 0.03
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

    test "score does not affect bar heights" do
      @entry.update!(
        score: 10.0,
        macro_expl: { "Autres" => 0.6, "Dettes-sociales" => 0.4 }
      )

      data_low_score = WaterfallChartBuilder.new(@entry).build

      @entry.update!(score: 99.0)
      data_high_score = WaterfallChartBuilder.new(@entry).build

      assert_equal data_low_score[:values], data_high_score[:values]
    end
  end
end
