# frozen_string_literal: true

require "test_helper"

class DetectionWidgetableTest < ActiveSupport::TestCase
  include DetectionWidgetable

  setup do
    @list = lists(:list_test_2025)
    @list.update!(precision_alerte_elevee: 85.5, precision_alerte_moderee: 72.25)
  end

  test "format_detection_precision uses elevee precision for F1 alert" do
    entry = CompanyScoreEntry.new(alert: "Alerte seuil F1")

    assert_equal "85,5%", send(:format_detection_precision, @list, entry)
  end

  test "format_detection_precision uses moderee precision for F2 alert" do
    entry = CompanyScoreEntry.new(alert: "Alerte seuil F2")

    assert_equal "72,25%", send(:format_detection_precision, @list, entry)
  end

  test "format_detection_precision omits decimals for whole numbers" do
    @list.update!(precision_alerte_elevee: 45)

    entry = CompanyScoreEntry.new(alert: "Alerte seuil F1")

    assert_equal "45%", send(:format_detection_precision, @list, entry)
  end

  test "format_detection_precision returns non disponible when precision is missing" do
    @list.update!(precision_alerte_elevee: nil)

    entry = CompanyScoreEntry.new(alert: "Alerte seuil F1")

    assert_equal "non disponible", send(:format_detection_precision, @list, entry)
  end

  test "format_detection_precision returns non disponible for unsupported alerts" do
    entry = CompanyScoreEntry.new(alert: "Plans")

    assert_equal "non disponible", send(:format_detection_precision, @list, entry)
  end
end
