# frozen_string_literal: true

# Provides methods to calculate detection widget data (criticite, data_date, etc.)
module DetectionWidgetable
  extend ActiveSupport::Concern

  private

  # Get the last list and entry for the current company
  # @return [Array<List, CompanyScoreEntry>] Returns [last_list, entry] or [nil, nil] if not found
  def fetch_last_list_and_entry
    last_list = List.order(code: :desc).first
    return [nil, nil] unless last_list

    entry = CompanyScoreEntry.find_by(siren: @company.siren, list_name: last_list.label)
    [last_list, entry]
  end

  # Calculate criticite from entry's alert field
  # @param entry [CompanyScoreEntry] The company score entry
  # @return [String] "élevé", "modéré", or "faible"
  def calculate_criticite(entry)
    return "faible" unless entry&.alert

    case entry.alert.downcase
    when "alerte seuil f1"
      "élevé"
    when "alerte seuil f2"
      "modéré"
    else
      "faible"
    end
  end

  # Format data_date as the last day of the month preceding the month of list_date
  # @param list [List] The list
  # @param _entry [CompanyScoreEntry] The company score entry (unused, kept for compatibility)
  # @return [String] Formatted date or "Date non disponible"
  def format_data_date(list, _entry)
    return "Date non disponible" unless list&.list_date

    # Ensure we're working with a Date object
    list_date = list.list_date.to_date

    # Get the last day of the month preceding the month of list_date
    # Example: if list_date is 2025-09-01, we want 2025-08-31
    preceding_month_last_day = list_date.beginning_of_month - 1.day
    I18n.l(preceding_month_last_day, format: :long, locale: :fr)
  end
end
