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

  test "markdown does not wrap content in an outer empty paragraph" do
    html = markdown("Bonjour")

    assert_equal "<p>Bonjour</p>\n", html
    assert_no_match(%r{<p>\s*</p>}, html)
  end

  test "render_markdown strips empty paragraphs used for spacing" do
    html = strip_empty_markdown_paragraphs("<p></p>\n<p>Contenu</p>\n<p><br></p>\n")

    assert_equal "\n<p>Contenu</p>\n\n", html
  end

  test "normalize_markdown_list_markers converts exotic bullets to markdown lists" do
    source = "\tCharge exceptionnelle\n•\tPoint de vigilance\n- Packaging"

    assert_equal "- Charge exceptionnelle\n- Point de vigilance\n- Packaging",
                 normalize_markdown_list_markers(source)
  end

  test "markdown renders normalized exotic bullets as list items" do
    html = markdown(" Augmentation énergie\n• Masse salariale")

    assert_includes html, "<ul>"
    assert_includes html, "<li>Augmentation énergie"
    assert_includes html, "<li>Masse salariale"
  end

  test "detection_widget_intro_content returns fallback when zone is missing" do
    Zone.stub(:find_by, nil) do
      assert_equal "Contenu en cours de construction",
                   detection_widget_intro_content(criticite: "élevé", data_date: "31 décembre 2024", precision: "85,5%")
    end
  end

  test "date_invalid_message includes a real date example" do
    message = date_invalid_message

    assert_includes message, "12/05/1984"
    assert_match(/date valide/i, message)
  end
end
