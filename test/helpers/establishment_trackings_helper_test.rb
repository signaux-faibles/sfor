# frozen_string_literal: true

require "test_helper"

class EstablishmentTrackingsHelperTest < ActionView::TestCase
  test "modified_at_aria_sort returns none when column is not sorted" do
    assert_equal "none", modified_at_aria_sort({ q: {} })
  end

  test "modified_at_aria_sort returns ascending for asc sort" do
    assert_equal "ascending", modified_at_aria_sort({ q: { "s" => "modified_at asc" } })
  end

  test "modified_at_aria_sort returns descending for desc sort" do
    assert_equal "descending", modified_at_aria_sort({ q: { "s" => "modified_at desc" } })
  end
end
