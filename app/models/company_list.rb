class CompanyList < ApplicationRecord
  STANDARD_ALERT_VALUES = ["Alerte seuil F1", "Alerte seuil F2"].freeze
  CRP_ALERT_VALUES = %w[Plans Ratios].freeze
  MEANINGFUL_ALERT_VALUES = (STANDARD_ALERT_VALUES + CRP_ALERT_VALUES).freeze
  NO_ALERT_LABEL = "Pas d'alerte".freeze

  belongs_to :company, foreign_key: :siren, primary_key: :siren, optional: false
  belongs_to :list

  validates :siren, presence: true, length: { is: 9 }
  validates :siren, uniqueness: { scope: :list_id }

  # Alerts shown in list search/results for the current user (F1/F2; + Plans/Ratios for CRP).
  def self.alerts_visible_to_user(crp_member:)
    crp_member ? MEANINGFUL_ALERT_VALUES : STANDARD_ALERT_VALUES
  end

  # True when alert is a current detection (F1, F2, Plans, or Ratios) — not blank or "Pas d'alerte".
  def self.meaningful_alert?(alert)
    value = alert.to_s.strip
    return false if value.blank?
    return false if value.casecmp?(NO_ALERT_LABEL)

    MEANINGFUL_ALERT_VALUES.any? { |meaningful| meaningful.casecmp?(value) }
  end
end
