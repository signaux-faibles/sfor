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

  # Format data_date from list_date or entry.created_at
  # @param list [List] The list
  # @param entry [CompanyScoreEntry] The company score entry
  # @return [String] Formatted date or "Date non disponible"
  def format_data_date(list, entry)
    if list&.list_date
      I18n.l(list.list_date, format: :long, locale: :fr)
    elsif entry&.created_at
      I18n.l(entry.created_at.to_date, format: :long, locale: :fr)
    else
      "Date non disponible"
    end
  end
end
