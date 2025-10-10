module CompaniesHelper
  def active_filter_tags(params)
    return "" unless params[:q]

    tags = []
    add_search_tags(tags, params[:q])
    add_department_tag(tags, params[:q])
    add_campaign_tag(tags, params[:q])
    add_activity_sector_tag(tags, params[:q])
    add_list_tag(tags, params[:q])

    tags.join(" ").html_safe
  end

  private

  def add_search_tags(tags, query)
    add_tag_if_present(tags, "SIREN", query[:siren_cont])
    add_tag_if_present(tags, "SIRET", query[:siret_cont])
    add_tag_if_present(tags, "Raison Sociale", query[:raison_sociale_cont])
    add_tag_if_present(tags, "Effectif", query[:effectif_eq])
  end

  def add_tag_if_present(tags, label, value)
    return unless value.blank?

    tags << content_tag(:p, "#{label}: #{value}", class: "fr-tag")
  end

  def add_department_tag(tags, query)
    return unless query[:department_id_eq].blank?

    department = Department.find_by(id: query[:department_id_eq])
    return unless department

    tags << content_tag(:p, "Département: #{department.name} (#{department.code})", class: "fr-tag")
  end

  def add_campaign_tag(tags, query)
    return unless query[:campaigns_id_eq].blank?

    campaign = Campaign.find_by(id: query[:campaigns_id_eq])
    return unless campaign

    tags << content_tag(:p, "Campagne: #{campaign.name}", class: "fr-tag")
  end

  def add_activity_sector_tag(tags, query)
    return unless query[:activity_sector_id_eq].blank?

    activity_sector = ActivitySector.find_by(id: query[:activity_sector_id_eq])
    return unless activity_sector

    tags << content_tag(:p, "Secteur d'activité: #{activity_sector.label}", class: "fr-tag")
  end

  def add_list_tag(tags, query)
    return unless query[:lists_id_eq].blank?

    list = List.find_by(id: query[:lists_id_eq])
    return unless list

    tags << content_tag(:p, "Liste: #{list.label}", class: "fr-tag")
  end

  def format_date_with_age(timestamp)
    return "" if timestamp.blank?

    date = Time.at(timestamp).to_date
    age = Date.today.year - date.year
    age -= 1 if Date.today < date.change(year: Date.today.year)

    "#{date.strftime('%d/%m/%Y')} (#{age} ans)"
  end
end
