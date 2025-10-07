class OsfEffectif < ApplicationRecord
  belongs_to :establishment, foreign_key: :siret, primary_key: :siret

  validates :siret, presence: true, length: { is: 14 }
  validates :periode, presence: true
end
