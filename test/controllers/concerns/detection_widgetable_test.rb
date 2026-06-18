# frozen_string_literal: true

require "test_helper"

class DetectionWidgetableTest < ActiveSupport::TestCase
  include DetectionWidgetable

  test "format_detection_score rounds to nearest integer" do
    entry = CompanyScoreEntry.new(score: 98.1147164549)

    assert_equal "98", send(:format_detection_score, entry)
  end

  test "format_detection_score rounds half up" do
    entry = CompanyScoreEntry.new(score: 75.5)

    assert_equal "76", send(:format_detection_score, entry)
  end

  test "format_detection_score returns non disponible when score is nil" do
    assert_equal "non disponible", send(:format_detection_score, CompanyScoreEntry.new)
  end
end
