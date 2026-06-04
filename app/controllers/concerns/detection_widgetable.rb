# frozen_string_literal: true

# Provides methods to calculate detection widget data (criticite, data_date, etc.)
module DetectionWidgetable
  extend ActiveSupport::Concern

  MEANINGFUL_ALERT_VALUES = CompanyList::MEANINGFUL_ALERT_VALUES.map(&:downcase).freeze
  NO_ALERT_LABEL = "pas d'alerte"

  private

  # Get the last list and the latest score entry for the current company in that list.
  # @return [Array<List, CompanyScoreEntry>] Returns [last_list, entry] or [nil, nil] if not found
  def fetch_last_list_and_entry
    last_list = List.order(code: :desc).first
    return [nil, nil] unless last_list

    entry = latest_score_entry_for_list(last_list)
    [last_list, entry]
  end

  # True when the company appears in the latest list (same source as list#show).
  def company_in_last_list?(last_list)
    return false unless last_list

    CompanyList.exists?(siren: @company.siren, list_id: last_list.id)
  end

  def latest_score_entry_for_list(list)
    CompanyScoreEntry
      .where(siren: @company.siren, list_name: list.label)
      .order(created_at: :desc)
      .first
  end

  # True when the entry carries a detection-relevant alert (F1, F2, Plans, or Ratios).
  def meaningful_alert?(entry)
    alert = entry&.alert&.to_s&.strip # rubocop:disable Style/SafeNavigationChainLength
    return false if alert.blank?
    return false if alert.casecmp?(NO_ALERT_LABEL)

    MEANINGFUL_ALERT_VALUES.include?(alert.downcase)
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
