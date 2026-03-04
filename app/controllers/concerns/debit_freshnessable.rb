# frozen_string_literal: true

module DebitFreshnessable
  def data_freshness_index(import_name, periodes)
    data_freshness = Import.find_by(name: import_name)&.data_freshness
    return nil if data_freshness.blank?

    freshness_month = data_freshness.to_date.beginning_of_month.iso8601
    periodes.index(freshness_month)
  end

  def debit_freshness_index(periodes)
    data_freshness_index("osf_debit", periodes)
  end

  def cotisation_freshness_index(periodes)
    data_freshness_index("osf_cotisation", periodes)
  end

  def delai_freshness_index(periodes)
    data_freshness_index("osf_delai", periodes)
  end

  def ap_freshness_index(periodes)
    data_freshness_index("osf_ap", periodes)
  end

  def effectif_freshness_index(periodes)
    data_freshness_index("osf_effectif", periodes)
  end

  def effectif_ent_freshness_index(periodes)
    data_freshness_index("osf_effectif_ent", periodes)
  end
end
