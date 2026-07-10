# frozen_string_literal: true

require "test_helper"

class SizeTest < ActiveSupport::TestCase
  test "name_for_effectif returns expected categories" do
    assert_nil Size.name_for_effectif(nil)
    assert_equal "TPE", Size.name_for_effectif(0)
    assert_equal "TPE", Size.name_for_effectif(9)
    assert_equal "PME", Size.name_for_effectif(10)
    assert_equal "PME", Size.name_for_effectif(249)
    assert_equal "ETI", Size.name_for_effectif(250)
    assert_equal "ETI", Size.name_for_effectif(4999)
    assert_equal "GE", Size.name_for_effectif(5000)
    assert_equal "GE", Size.name_for_effectif(10_000)
  end

  test "from_effectif returns matching size record" do
    assert_equal sizes(:pme), Size.from_effectif(50)
    assert_nil Size.from_effectif(nil)
  end
end
