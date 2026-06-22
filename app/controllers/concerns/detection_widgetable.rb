# frozen_string_literal: true

# Provides methods to calculate detection widget data (criticite, data_date, etc.)
module DetectionWidgetable
  extend ActiveSupport::Concern
  include ActiveSupport::NumberHelper

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
    CompanyList.meaningful_alert?(entry&.alert)
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

  # Format the alert precision for the detection widget intro zone.
  # @param list [List] The current list
  # @param entry [CompanyScoreEntry] The company score entry
  # @return [String] Formatted precision percentage or "non disponible"
  def format_detection_precision(list, entry)
    precision_value = detection_precision_for(list, entry)
    return "non disponible" if precision_value.nil?

    number_to_percentage(precision_value, precision: 2, strip_insignificant_zeros: true)
  end

  def detection_precision_for(list, entry)
    return nil unless list && entry&.alert

    case entry.alert.downcase
    when "alerte seuil f1"
      list.precision_alerte_elevee
    when "alerte seuil f2"
      list.precision_alerte_moderee
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
