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
end
