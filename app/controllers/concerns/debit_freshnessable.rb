# frozen_string_literal: true

module DebitFreshnessable
  def debit_freshness_index(periodes)
    debit_freshness = Import.find_by(name: "osf_debit")&.data_freshness
    return nil if debit_freshness.blank?

    freshness_month = debit_freshness.to_date.beginning_of_month.iso8601
    periodes.index(freshness_month)
  end
end
