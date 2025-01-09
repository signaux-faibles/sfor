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
      # Ajouter deux lignes vides pour la marge
      sheet.add_row []
      sheet.add_row []

      # Ligne d'en-tête avec style centré, bordures et couleur
      sheet.add_row ["", "Raison sociale", "Siret", "Département", "Participants", "Assignés", "Date de début", "Date de fin", "Statut", "Synthèse"],
                    style: Array.new(10) { |i| i.zero? ? nil : header_style(sheet) }

      @establishment_trackings.each do |tracking|
        summary = tracking.summaries.find_by(network: @user.non_codefi_network)
        sheet.add_row [
                        "",
                        tracking.establishment.raison_sociale,
                        tracking.establishment.siret.to_s,
                        tracking.establishment&.department&.name,
                        tracking.participants.map(&:full_name).join(', '),
                        tracking.referents.map(&:full_name).join(', '),
                        tracking.start_date.present? ? tracking.start_date.strftime('%d/%m/%Y') : '-',
                        tracking.end_date.present? ? tracking.end_date.strftime('%d/%m/%Y') : '-',
                        tracking.aasm.human_state,
                        summary&.content || 'Aucune synthèse rédigée'
                      ],
                      style: Array.new(9, centered_style(sheet)) + [summary_style(sheet)],
                      types: [nil, :string, nil, nil, nil, nil, nil, nil, nil, :string]
      end

      # Autosize des colonnes (sauf les colonnes fixes)
      autosize_columns(sheet)

      # Appliquer les bordures
      apply_borders(sheet)

      # Supprimer les bordures de la colonne A
      clear_borders_in_column_a(sheet)

      # Fixer la largeur et wrap text pour Participants et Assignés
      set_fixed_width_columns(sheet)
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

  def header_style(sheet)
    sheet.styles.add_style(
      b: true,
      alignment: { horizontal: :center, vertical: :center },
      sz: 12,
      bg_color: 'CCCCCC',
      border: { style: :thick, color: '000000' }
    )
  end

  def centered_style(sheet)
    sheet.styles.add_style(
      alignment: { horizontal: :center, vertical: :center },
      border: { style: :thin, color: '000000' }
    )
  end

  def summary_style(sheet)
    sheet.styles.add_style(
      alignment: { horizontal: :left, vertical: :center, wrap_text: true },
      border: { style: :thin, color: '000000' }
    )
  end

  def autosize_columns(sheet)
    return if sheet.rows.empty?

    column_count = sheet.rows.first&.cells&.size.to_i
    return if column_count <= 2

    # Autosize toutes les colonnes sauf la première (marge) et la dernière ("Synthèse" avec une largeur fixe)
    sheet.column_widths(5, *Array.new(column_count - 3, nil), 50)
  end

  def apply_borders(sheet)
    return if sheet.rows.empty?

    last_row = sheet.rows.size
    last_column = sheet.rows.first&.cells&.size.to_i

    # Appliquer les bordures uniquement à partir de la colonne B
    if last_column > 1 && last_row > 2
      range = "B3:#{('A'.ord + last_column - 1).chr}#{last_row + 2}"
      sheet.add_style(range, border: { style: :thick, color: '000000' })
    end
  end

  def clear_borders_in_column_a(sheet)
    sheet.rows.each do |row|
      next unless row.cells[0]

      # Crée un style sans bordure
      no_border_style = sheet.styles.add_style(border: nil)
      row.cells[0].style = no_border_style
    end
  end

  def set_fixed_width_columns(sheet)
    # Fixer la largeur des colonnes Participants et Assignés
    sheet.column_info[4].width = 30
    sheet.column_info[5].width = 30

    wrap_text_style = sheet.styles.add_style(
      alignment: { wrap_text: true, horizontal: :center, vertical: :center },
      border: { style: :thin, color: '000000' }
    )

    sheet.rows.each_with_index do |row, index|
      next if index < 3  # Ignorer les marges et l'en-tête
      row.cells[4]&.style = wrap_text_style
      row.cells[5]&.style = wrap_text_style
    end
  end
end
