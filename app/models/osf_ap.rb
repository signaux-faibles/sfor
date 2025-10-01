class OsfAp < ApplicationRecord
  belongs_to :establishment, foreign_key: :siret, primary_key: :siret

  validates :siret, presence: true, length: { is: 14 }
  validates :siren, presence: true, length: { is: 9 }
  validates :periode, presence: true
end
