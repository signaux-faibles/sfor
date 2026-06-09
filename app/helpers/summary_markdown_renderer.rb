# frozen_string_literal: true

class SummaryMarkdownRenderer < Redcarpet::Render::HTML
  def header(text, header_level)
    # Summary block title is h3; subsections in content should be h4 or below.
    adjusted_level = header_level <= 3 ? 4 : [header_level + 1, 6].min
    "<h#{adjusted_level}>#{text}</h#{adjusted_level}>\n"
  end
end
