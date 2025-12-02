class OsfAp < ApplicationRecord
  belongs_to :establishment, foreign_key: :siret, primary_key: :siret

  validates :siret, presence: true, length: { is: 14 }
  validates :siren, presence: true, length: { is: 9 }
  validates :periode, presence: true

  def self.active_activite_partielle?(siret) # rubocop:disable Metrics/AbcSize
    # Get the last list by list_date (most recent list_date)
    last_list = List.where.not(list_date: nil).order(list_date: :desc).first

    return "Na" unless last_list

    # Check if current date is superior or equal to the list_date
    return "Na" unless Date.current >= last_list.list_date

    # Get the month that precedes the list_date month
    # e.g., if list_date is 2025-08-03, we look into July 2025
    previous_month_start = last_list.list_date.beginning_of_month - 1.month
    previous_month_end = previous_month_start.end_of_month

    # Check if there's any entry in OsfAp for this month
    entries = OsfAp.where(siret: siret)
                   .where(periode: previous_month_start..previous_month_end)

    # If no entry exists, return "Na"
    return "Na" unless entries.exists?

    # If entry exists, check if etp_consomme is > 0
    has_active_ap = entries.where("etp_consomme > 0").exists?

    has_active_ap ? true : false
  end
end
