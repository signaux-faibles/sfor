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

  test "detection_widget_intro_content returns fallback when zone is missing" do
    Zone.stub(:find_by, nil) do
      assert_equal "Contenu en cours de construction",
                   detection_widget_intro_content(criticite: "élevé", data_date: "31 décembre 2024", score: "75,5")
    end
  end

  test "detection_widget_intro_content substitutes dynamic values" do
    content = detection_widget_intro_content(criticite: "élevé", data_date: "31 décembre 2024", score: "75,5")

    assert_includes content, "élevé"
    assert_includes content, "31 décembre 2024"
    assert_includes content, "75,5"
    assert_not_includes content, "%<criticite>s"
    assert_not_includes content, "%<data_date>s"
    assert_not_includes content, "%<score>s"
  end
end
