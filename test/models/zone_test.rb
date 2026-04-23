require "test_helper"

class ZoneTest < ActiveSupport::TestCase
  test "key should be unique" do
    duplicate = Zone.new(
      key: zones(:support_page_body).key,
      content: "Content"
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors.details[:key].pluck(:error), :taken
  end

  test "content_for returns fallback when missing" do
    content = Zone.content_for("unknown_zone_key", fallback: "fallback value")

    assert_equal "fallback value", content
  end
end
