# app/services/excel/establishment_tracking_generator.rb
module Excel
  module Styles
    def header_style(sheet)
      sheet.styles.add_style(
        b: true,
        alignment: { horizontal: :center, vertical: :center },
        sz: 12,
        bg_color: "CCCCCC",
        border: { style: :thick, color: "000000" }
      )
    end

    def centered_style(sheet)
      sheet.styles.add_style(
        alignment: { horizontal: :center, vertical: :center },
        border: { style: :thin, color: "000000" }
      )
    end

    def summary_style(sheet)
      sheet.styles.add_style(
        alignment: { horizontal: :left, vertical: :center, wrap_text: true },
        border: { style: :thin, color: "000000" }
      )
    end

    def wrap_text_style(sheet)
      sheet.styles.add_style(
        alignment: { wrap_text: true, horizontal: :center, vertical: :center },
        border: { style: :thin, color: "000000" }
      )
    end
  end

  module FilterHelpers
    def filter_label(attribute) # rubocop:disable Metrics/MethodLength
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

    def extract_filters # rubocop:disable Metrics/MethodLength
      @filters.conditions.map do |condition|
        attribute = condition.attributes.map(&:name).join(", ")
        predicate = condition.predicate.name
        raw_values = condition.values.map(&:value)

        cleaned_values = raw_values.compact_blank.map do |value|
          format_value(attribute, value)
        end

        {
          attribute: attribute,
          predicate: predicate,
          values: cleaned_values.join(", ")
        }
      end
    end

    def format_value(attribute, value) # rubocop:disable Metrics/CyclomaticComplexity
      case attribute
      when "state" then format_state_value(value)
      when "establishment_department_id" then format_department_value(value)
      when "tracking_labels_id" then format_tracking_labels_value(value)
      when "sectors_id" then format_sectors_value(value)
      when "size_id" then format_size_value(value)
      when "criticality_id" then format_criticality_value(value)
      when "start_date" then format_date_value(value)
      else value
      end
    end

    def format_state_value(value)
      EstablishmentTracking.aasm.states.find { |s| s.name.to_s == value.to_s }&.human_name || value
    end

    def format_department_value(value)
      Rails.logger.debug "Departements"
      Rails.logger.debug value
      value.split(",").map { |id| Department.find_by(id: id)&.name || id }.join(", ")
    end

    def format_tracking_labels_value(value)
      value.split(",").map { |id| TrackingLabel.find_by(id: id)&.name || id }.join(", ")
    end

    def format_sectors_value(value)
      value.split(",").map { |id| Sector.find_by(id: id)&.name || id }.join(", ")
    end

    def format_size_value(value)
      Size.find_by(id: value)&.name || value
    end

    def format_criticality_value(value)
      Criticality.find_by(id: value)&.name || value
    end

    def format_date_value(value)
      Date.parse(value).strftime("%d/%m/%Y")
    rescue StandardError
      value
    end
  end

  class EstablishmentTrackingGenerator # rubocop:disable Metrics/ClassLength
    include Excel::Styles
    include FilterHelpers

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
        add_header_row(sheet)
        add_tracking_rows(sheet)
        format_sheet(sheet)
      end
    end

    def add_header_row(sheet) # rubocop:disable Metrics/MethodLength
      headers = [
        "Raison sociale",
        "Siret",
        "Département",
        "Participants",
        "Référents",
        "Date de début",
        "Date de fin",
        "Date de dernière modification",
        "Statut",
        "Criticité",
        "Actions réalisées",
        "Filières",
        "Région",
        "Administrations",
        "Taille",
        "Synthèse de mon administration",
        "Synthèse CODEFI"
      ]
      sheet.add_row headers, style: Array.new(17) { header_style(sheet) }
    end

    def add_tracking_rows(sheet)
      @establishment_trackings.each do |tracking|
        sheet.add_row prepare_tracking_row(tracking, sheet),
                      style: Array.new(15, centered_style(sheet)) + [summary_style(sheet)] + [summary_style(sheet)],
                      types: [nil, :string, :string, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
                              :string, :string]
      end
    end

    def prepare_tracking_row(tracking, _sheet) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
      [
        tracking.establishment.raison_sociale,
        tracking.establishment.siret.to_s,
        tracking.establishment&.department&.name,
        tracking.participants.map(&:full_name).uniq.join(", "),
        tracking.referents.map(&:full_name).uniq.join(", "),
        format_date(tracking.start_date),
        format_date(tracking.end_date),
        format_date(tracking.modified_at),
        tracking.aasm.human_state,
        tracking.criticality&.name,
        tracking.user_actions.map(&:name).uniq.join(", "),
        tracking.sectors.map(&:name).uniq.join(", "),
        tracking.establishment&.department&.region&.libelle, # rubocop:disable Style/SafeNavigationChainLength
        tracking.referents.filter_map { |referent| referent&.entity&.name }.uniq.join(", "),
        tracking.size&.name,
        fetch_summary_content(tracking, @user.non_codefi_network),
        fetch_summary_content(tracking, Network.find_by(name: "CODEFI"))
      ]
    end

    def fetch_summary_content(tracking, network)
      tracking.summaries.find_by(network: network)&.content || default_summary_text(network)
    end

    def default_summary_text(network)
      if network.name == "CODEFI"
        "Aucune synthèse CODEFI rédigée"
      else
        "Aucune synthèse rédigée par mon administration"
      end
    end

    def format_date(date)
      date.present? ? date.strftime("%d/%m/%Y") : "-"
    end

    def format_sheet(sheet)
      autosize_columns(sheet)
      apply_borders(sheet)
      fixed_width_columns(sheet)
    end

    def autosize_columns(sheet)
      return if sheet.rows.empty?

      column_count = sheet.rows.first&.cells&.size.to_i
      return if column_count <= 2

      # Autosize toutes les colonnes sauf les colonnes avec largeur fixe
      sheet.column_widths(*Array.new(column_count - 2, nil), 50)
    end

    def apply_borders(sheet)
      return if sheet.rows.empty?

      last_row = sheet.rows.size
      last_column = sheet.rows.first&.cells&.size.to_i

      # Appliquer les bordures à partir de la première colonne
      if last_column.positive? && last_row > 2
        range = "A1:#{('A'.ord + last_column - 1).chr}#{last_row}"
        sheet.add_style(range, border: { style: :thick, color: "000000" })
      end
    end

    def fixed_width_columns(sheet)
      column_widths(sheet)
      apply_wrap_text_styles(sheet)
    end

    def column_widths(sheet)
      sheet.column_info[3].width = 30
      sheet.column_info[4].width = 30
    end

    def apply_wrap_text_styles(sheet)
      sheet.rows.each_with_index do |row, index|
        next if index < 3 # Ignorer les marges et l'en-tête

        apply_wrap_text_style(row, sheet)
      end
    end

    def apply_wrap_text_style(row, sheet)
      row.cells[3]&.style = wrap_text_style(sheet)
      row.cells[4]&.style = wrap_text_style(sheet)
    end

    def add_filter_details_sheet(workbook)
      workbook.add_worksheet(name: "Filtres") do |sheet|
        sheet.add_row %w[Filtre Valeurs]
        extract_filters.each do |filter|
          sheet.add_row [
            filter_label(filter[:attribute]),
            filter[:values]
          ]
        end
      end
    end
  end
end
