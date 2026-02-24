class OsfEffectif < ApplicationRecord
  belongs_to :establishment, foreign_key: :siret, primary_key: :siret

  validates :siret, presence: true, length: { is: 14 }
  validates :periode, presence: true

  def self.last_effectif_for_siret(siret)
    where(siret: siret)
      .order(periode: :desc)
      .limit(1)
      .pick(:effectif)
  end

  # Returns the effectif value if the latest row for this siret is in the same month as
  # data_freshness_date; otherwise nil (caller typically displays "-").
  # Latest row: prefer is_latest = true, else most recent by periode.
  def self.last_effectif_for_siret_in_freshness_month(siret, data_freshness_date)
    return nil if data_freshness_date.blank?

    latest = where(siret: siret).where(is_latest: true).limit(1).first
    latest ||= where(siret: siret).order(periode: :desc).limit(1).first
    return nil if latest.blank?

    freshness = data_freshness_date.to_date
    same_month = latest.periode.year == freshness.year && latest.periode.month == freshness.month
    same_month ? latest.effectif : nil
  end
end
