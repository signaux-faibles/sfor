module CompaniesHelper
  def active_filter_tags(params)
    tags = []

    if params[:q]
      tags << content_tag(:p, "SIREN: #{params[:q][:siren_cont]}", class: "fr-tag") if params[:q][:siren_cont].present?

      tags << content_tag(:p, "SIRET: #{params[:q][:siret_cont]}", class: "fr-tag") if params[:q][:siret_cont].present?

      if params[:q][:raison_sociale_cont].present?
        tags << content_tag(:p, "Raison Sociale: #{params[:q][:raison_sociale_cont]}", class: "fr-tag")
      end

      if params[:q][:effectif_eq].present?
        tags << content_tag(:p, "Effectif: #{params[:q][:effectif_eq]}", class: "fr-tag")
      end

      if params[:q][:department_id_eq].present?
        department = Department.find_by(id: params[:q][:department_id_eq])
        tags << content_tag(:p, "Département: #{department.name} (#{department.code})", class: "fr-tag") if department
      end

      if params[:q][:campaigns_id_eq].present?
        campaign = Campaign.find_by(id: params[:q][:campaigns_id_eq])
        tags << content_tag(:p, "Campagne: #{campaign.name}", class: "fr-tag") if campaign
      end

      if params[:q][:activity_sector_id_eq].present?
        activity_sector = ActivitySector.find_by(id: params[:q][:activity_sector_id_eq])
        tags << content_tag(:p, "Secteur d'activité: #{activity_sector.label}", class: "fr-tag") if activity_sector
      end

      if params[:q][:lists_id_eq].present?
        list = List.find_by(id: params[:q][:lists_id_eq])
        tags << content_tag(:p, "Liste: #{list.label}", class: "fr-tag") if list
      end
    end

    tags.join(" ").html_safe
  end
end
