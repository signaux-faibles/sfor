require "redcarpet"

module ApplicationHelper
  def current?(key, path)
    key.to_s if current_page? path
  end

  def dsfr_class_for(flash_type)
    case flash_type
    when "notice"
      "info"
    when "error"
      "error"
    when "alert"
      "warning"
    else
      flash_type.to_s
    end
  end

  def markdown(text) # rubocop:disable Metrics/MethodLength
    options = {
      filter_html: true,
      hard_wrap: true,
      link_attributes: { rel: "nofollow", target: "_blank" },
      space_after_headers: true,
      fenced_code_blocks: true
    }
    extensions = {
      autolink: true,
      superscript: true,
      disable_indented_code_blocks: true,
      tables: true
    }

    renderer = ::Redcarpet::Render::HTML.new(options)
    markdown = ::Redcarpet::Markdown.new(renderer, extensions)
    markdown.render(text).html_safe
  end

  private

  def badge_class_for(state)
    case state
    when "En cours"
      "fr-badge fr-badge--info fr-badge--sm fr-badge--no-icon"
    when "Sous surveillance"
      "fr-badge fr-badge--warning fr-badge--sm fr-badge--no-icon"
    when "Terminé"
      "fr-badge fr-badge--success fr-badge--sm fr-badge--no-icon"
    else
      "fr-badge fr-badge--error fr-badge--sm fr-badge--no-icon"
    end
  end

  def criticality_class_for(level)
    case level
    when "Criticité élevée"
      "fr-badge fr-badge--error fr-badge--sm fr-badge--no-icon"
    when "Criticité modérée"
      "fr-badge fr-badge--warning fr-badge--sm fr-badge--no-icon"
    when "Niveau vert", "Pas de criticité"
      "fr-badge fr-badge--success fr-badge--sm fr-badge--no-icon"
    else
      "fr-badge fr-badge--sm fr-badge--no-icon"
    end
  end

  # @TODO : use criticality_class_for instead.
  def criticality_style_for(level)
    case level
    when "Criticité élevée"
      "background-color: var(--warning-950-100); color: var(--error-425-625);"
    when "Criticité modérée"
      "background-color: var(--brown-opera-950-100); color: var(--warning-425-625);"
    when "Niveau vert", "Pas de criticité"
      "background-color: var(--success-950-100); color: var(--success-425-625);"
    else
      "background-color: grey; color: black;"
    end
  end

  def state_style_for(state)
    case state
    when "Terminé"
      "background-color: var(--background-default-grey-active); color: var(--text-mention-grey);"
    when "Sous surveillance"
      "background-color: var(--beige-gris-galet-950-100); color: var(--brown-opera-sun-395);"
    end
  end
end
