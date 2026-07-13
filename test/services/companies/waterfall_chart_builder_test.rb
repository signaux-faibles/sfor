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

      assert_equal ["Santé financière", "Effectif de l'entreprise", "Dettes sociales"], data[:labels]
      assert_in_delta 50.0, data[:values][0][1] - data[:values][0][0], 0.01
      assert_in_delta 100.0, data[:values].last[1], 0.01
    end

    test "includes cluster economique and age groups with display labels" do
      @entry.update!(
        macro_expl: {
          "Cluster-économique" => 0.2,
          "Age-de-l'entreprise" => 0.3,
          "Dettes-sociales" => 0.5
        }
      )

      data = WaterfallChartBuilder.new(@entry).build

      assert_equal ["Dettes sociales", "Âge de l'entreprise", "Secteur d'activité"], data[:labels]
    end

    test "matches slide example with threshold 0.4" do
      @entry.update!(
        macro_expl: {
          "Dettes-sociales" => -0.2,
          "Variation-de-l'effectif-de-l'entreprise" => 0.5,
          "Données-financières" => 1.5,
          "Age-de-l'entreprise" => 0.3
        }
      )

      stub_const(WaterfallChartBuilder, :CONTRIBUTION_THRESHOLD, 0.4) do
        data = WaterfallChartBuilder.new(@entry).build

        assert_equal ["Santé financière", "Effectif de l'entreprise"], data[:labels]
        assert_equal [[0.0, 75.0], [75.0, 100.0]], data[:values]
      end
    end

    test "returns empty chart when no delta passes threshold" do
      @entry.update!(
        macro_expl: {
          "Dettes-sociales" => 0.01,
          "Données-financières" => 0.02,
          "Age-de-l'entreprise" => 0.03
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

    test "supports legacy Autres key for age on older lists" do
      @entry.update!(
        macro_expl: {
          "Autres" => 0.6,
          "Dettes-sociales" => 0.4
        }
      )

      data = WaterfallChartBuilder.new(@entry).build

      assert_equal ["Âge de l'entreprise", "Dettes sociales"], data[:labels]
      assert_in_delta 60.0, data[:values][0][1] - data[:values][0][0], 0.01
    end

    test "prefers Age-de-l'entreprise over legacy Autres when both are present" do
      @entry.update!(
        macro_expl: {
          "Autres" => 0.2,
          "Age-de-l'entreprise" => 0.6,
          "Dettes-sociales" => 0.4
        }
      )

      data = WaterfallChartBuilder.new(@entry).build

      assert_in_delta 60.0, data[:values].first[1] - data[:values].first[0], 0.01
    end

    test "score does not affect bar heights" do
      @entry.update!(
        score: 10.0,
        macro_expl: { "Age-de-l'entreprise" => 0.6, "Dettes-sociales" => 0.4 }
      )

      data_low_score = WaterfallChartBuilder.new(@entry).build

      @entry.update!(score: 99.0)
      data_high_score = WaterfallChartBuilder.new(@entry).build

      assert_equal data_low_score[:values], data_high_score[:values]
    end
  end
end
