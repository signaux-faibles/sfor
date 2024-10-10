module ApplicationHelper
  def current?(key, path)
    key.to_s if current_page? path
  end

  def dsfr_class_for(flash_type)
    case flash_type
    when 'notice'
      'info'
    when 'error'
      'error'
    when 'alert'
      'warning'
    else
      flash_type.to_s
    end
  end

  def breadcrumb
    content_tag(:nav, role: 'navigation', class: 'fr-breadcrumb', aria: { label: 'vous êtes ici :' }) do
      safe_join([
                  button_tag('Voir le fil d’Ariane', class: 'fr-breadcrumb__button', aria: { expanded: 'false', controls: 'breadcrumb-1' }),
                  content_tag(:div, class: 'fr-collapse', id: 'breadcrumb-1') do
                    content_tag(:ol, class: 'fr-breadcrumb__list') do
                      safe_join(
                        breadcrumb_items.map do |text, path, current|
                          content_tag(:li) do
                            if current
                              content_tag(:a, text, class: 'fr-breadcrumb__link', 'aria-current': 'page')
                            else
                              link_to(text, path, class: 'fr-breadcrumb__link')
                            end
                          end
                        end
                      )
                    end
                  end
                ])
    end
  end

  private

  def breadcrumb_items
    items = []
    items << ['Accompagnements', establishment_trackings_path]

    if controller_name == 'establishments' && action_name == 'show'
      items << ['Historique des accompagnements', nil, true]
    elsif controller_name == 'establishment_trackings' && action_name == 'show'
      establishment = @establishment_tracking&.establishment
      items << ['Historique des accompagnements', establishment_path(establishment)] if establishment
      items << ["Accompagnement - #{establishment&.raison_sociale}", establishment_establishment_tracking_path(establishment, @establishment_tracking), true]
    end

    items
  end
end
