# app/services/establishment_tracking_excel_generator.rb
class EstablishmentTrackingExcelGenerator
  def initialize(establishment_trackings, filters, user)
    @establishment_trackings = establishment_trackings
    @filters = filters
    @user = user
  end

  def generate
    package = Axlsx::Package.new
    workbook = package.workbook

    add_tracking_details_sheet(workbook)
    add_filter_details_sheet(workbook)

    package.to_stream.read
  end

  private

  def add_tracking_details_sheet(workbook)
    workbook.add_worksheet(name: "Accompagnements") do |sheet|
      sheet.add_row ["Raison sociale", "Siret", "Département", "Participants", "Assignés", "Date de début", "Statut", "Synthèse"]
      @establishment_trackings.each do |tracking|
        summary = tracking.summaries.find_by(network: @user.non_codefi_network)
        sheet.add_row [
                        tracking.establishment.raison_sociale,
                        tracking.establishment.siret,
                        tracking.establishment&.department.name,
                        tracking.participants.map(&:full_name).join(', '),
                        tracking.referents.map(&:full_name).join(', '),
                        tracking.start_date.present? ? tracking.start_date.strftime('%d/%m/%Y') : '-',
                        tracking.aasm.human_state,
                        summary&.content || 'Aucune synthèse rédigée'
                      ]
      end
    end
  end

  def add_filter_details_sheet(workbook)
    workbook.add_worksheet(name: "Filtres") do |sheet|
      sheet.add_row ["Filtre", "Valeurs"]
      extract_filters.each do |filter|
        sheet.add_row [
                        filter_label(filter[:attribute]),
                        filter[:values]
                      ]
      end
    end
  end

  def filter_label(attribute)
    {
      "establishment_raison_sociale" => "Raison sociale",
      "establishment_siret" => "SIRET",
      "establishment_department_id" => "Départements",
      "state" => "Statuts",
      "tracking_labels_id" => "Étiquettes",
      "sectors_id" => "Filières",
      "size_id" => "Taille",
      "criticality_id" => "Criticité",
      "start_date" => "Date de début"
    }[attribute] || attribute
  end

  def extract_filters
    @filters.conditions.map do |condition|
      attribute = condition.attributes.map(&:name).join(", ")
      predicate = condition.predicate.name
      raw_values = condition.values.map(&:value)

      # Remove empty strings and format values
      cleaned_values = raw_values.reject(&:blank?).map do |value|
        format_value(attribute, value)
      end

      {
        attribute: attribute,
        predicate: predicate,
        values: cleaned_values.join(", ")
      }
    end
  end

  def format_value(attribute, value)
    case attribute
    when "state"
      EstablishmentTracking.aasm.states.find { |s| s.name.to_s == value.to_s }&.human_name || value
    when "establishment_department_id"
      puts "Departements"
      puts value
      value.split(',').map { |id| Department.find_by(id: id)&.name || id }.join(", ")
    when "tracking_labels_id"
      value.split(',').map { |id| TrackingLabel.find_by(id: id)&.name || id }.join(", ")
    when "sectors_id"
      value.split(',').map { |id| Sector.find_by(id: id)&.name || id }.join(", ")
    when "size_id"
      Size.find_by(id: value)&.name || value
    when "criticality_id"
      Criticality.find_by(id: value)&.name || value
    when "start_date"
      Date.parse(value).strftime('%d/%m/%Y') rescue value
    else
      value
    end
  end
end