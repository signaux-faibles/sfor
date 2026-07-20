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
    def filter_label(attribute)
      {
        "establishment_siret" => "SIRET",
        "establishment_departement_eq" => "Départements",
        "establishment_departement_in" => "Départements",
        "state" => "Statuts",
        "tracking_labels_id" => "Étiquettes",
        "sectors_id" => "Filières",
        "establishment_company_size_id" => "Taille",
        "criticality_id" => "Criticité",
        "start_date" => "Date de début"
      }[attribute] || attribute
    end

    def extract_filters
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

    def format_value(attribute, value)
      case attribute
      when "state" then format_state_value(value)
      when "establishment_departement_eq", "establishment_departement_in" then format_department_value(value)
      when "tracking_labels_id" then format_tracking_labels_value(value)
      when "sectors_id" then format_sectors_value(value)
      when "establishment_company_size_id" then format_size_value(value)
      when "criticality_id" then format_criticality_value(value)
      when "start_date" then format_date_value(value)
      else value
      end
    end

    def format_state_value(value)
      EstablishmentTracking.aasm.states.find { |s| s.name.to_s == value.to_s }&.human_name || value
    end

    def format_department_value(value)
      value.split(",").map { |code| lookup_department_name(code) }.join(", ")
    end

    def format_tracking_labels_value(value)
      value.split(",").map { |id| lookup_tracking_label_name(id) }.join(", ")
    end

    def format_sectors_value(value)
      value.split(",").map { |id| lookup_sector_name(id) }.join(", ")
    end

    def format_size_value(value)
      lookup_size_name(value)
    end

    def format_criticality_value(value)
      lookup_criticality_name(value)
    end

    def format_date_value(value)
      Date.parse(value).strftime("%d/%m/%Y")
    rescue StandardError
      value
    end

    def lookup_department_name(code)
      @department_names ||= {}
      @department_names[code] ||= Department.find_by(code: code)&.name || code
    end

    def lookup_tracking_label_name(id)
      @tracking_label_names ||= {}
      @tracking_label_names[id] ||= TrackingLabel.find_by(id: id)&.name || id
    end

    def lookup_sector_name(id)
      @sector_names ||= {}
      @sector_names[id] ||= Sector.find_by(id: id)&.name || id
    end

    def lookup_size_name(id)
      @size_names ||= {}
      @size_names[id] ||= Size.find_by(id: id)&.name || id
    end

    def lookup_criticality_name(id)
      @criticality_names ||= {}
      @criticality_names[id] ||= Criticality.find_by(id: id)&.name || id
    end
  end

  class EstablishmentTrackingGenerator # rubocop:disable Metrics/ClassLength
    include Excel::Styles
    include FilterHelpers

    EXPORT_INCLUDES = [
      :criticality, :participants, :user_actions, :sectors, :summaries,
      { referents: :entity,
        establishment: { company: :size, department: :region } }
    ].freeze

    ROW_TYPES = [:string, :string, :string, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
                 :string, :string].freeze

    def initialize(establishment_trackings, filters, user)
      @establishment_trackings = establishment_trackings
      @filters = filters
      @user = user
      @user_network = user.non_codefi_network
      @codefi_network = Network.find_by(name: "CODEFI")
    end

    def generate
      package = Axlsx::Package.new(use_shared_strings: false)
      workbook = package.workbook

      add_tracking_details_sheet(workbook)
      add_filter_details_sheet(workbook)

      t = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      result = package.to_stream.read
      Rails.logger.info "[EstablishmentTrackingGenerator] to_stream.read: #{(Process.clock_gettime(Process::CLOCK_MONOTONIC) - t).round(2)}s"
      result
    end

    private

    def add_tracking_details_sheet(workbook)
      workbook.add_worksheet(name: "Accompagnements") do |sheet|
        add_header_row(sheet)

        t = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        add_tracking_rows(sheet)
        Rails.logger.info "[EstablishmentTrackingGenerator] add_tracking_rows (#{@establishment_trackings.size} trackings): #{(Process.clock_gettime(Process::CLOCK_MONOTONIC) - t).round(2)}s"

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
        "Effectif entreprise",
        "Effectif établissement",
        "Synthèse de mon administration",
        "Synthèse CODEFI"
      ]
      header_style_obj = header_style(sheet)
      sheet.add_row headers, style: Array.new(19, header_style_obj)
    end

    def add_tracking_rows(sheet)
      centered = centered_style(sheet)
      wrap = wrap_text_style(sheet)
      summary = summary_style(sheet)
      row_style = Array.new(4, centered) + [wrap, wrap] + Array.new(12, centered) + [summary, summary]

      @establishment_trackings.each do |tracking|
        sheet.add_row prepare_tracking_row(tracking), style: row_style, types: ROW_TYPES
      end
    end

    def prepare_tracking_row(tracking) # rubocop:disable Metrics/MethodLength
      [
        tracking.establishment&.raison_sociale.to_s,
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
        company_size_name(tracking),
        format_effectif(tracking.establishment&.company&.latest_effectif),
        format_effectif(tracking.establishment&.latest_effectif),
        fetch_summary_content(tracking, @user_network),
        fetch_summary_content(tracking, @codefi_network)
      ]
    end

    def fetch_summary_content(tracking, network)
      return default_summary_text(network) unless network

      summary = tracking.summaries.find { |entry| entry.network_id == network.id }
      summary&.content || default_summary_text(network)
    end

    def default_summary_text(network)
      if network&.name == "CODEFI"
        "Aucune synthèse CODEFI rédigée"
      else
        "Aucune synthèse rédigée par mon administration"
      end
    end

    def format_date(date)
      date.present? ? date.strftime("%d/%m/%Y") : "-"
    end

    def format_effectif(value)
      value.presence || "-"
    end

    def company_size_name(tracking)
      company = tracking.establishment&.company
      company&.size&.name
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

      sheet.column_widths(*Array.new(column_count - 2, nil), 50)
    end

    def apply_borders(sheet)
      return if sheet.rows.empty?

      last_row = sheet.rows.size
      last_column = sheet.rows.first&.cells&.size.to_i

      return unless last_column.positive? && last_row > 2

      range = "A1:#{('A'.ord + last_column - 1).chr}#{last_row}"
      sheet.add_style(range, border: { style: :thick, color: "000000" })
    end

    def fixed_width_columns(sheet)
      sheet.column_info[4].width = 30
      sheet.column_info[5].width = 30
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
