# frozen_string_literal: true

require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "summary_markdown renders subsections as h4 headings" do
    html = summary_markdown("### Actions\n\nContenu")

    assert_includes html, "<h4>Actions</h4>"
    assert_not_includes html, "<h3>Actions</h3>"
  end

  test "markdown keeps original heading levels" do
    html = markdown("### Actions")

    assert_includes html, "<h3>Actions</h3>"
  end
end
