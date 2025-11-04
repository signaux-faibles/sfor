class OsfEntEffectif < ApplicationRecord
  belongs_to :company, foreign_key: :siren, primary_key: :siren

  validates :siren, presence: true, length: { is: 9 }
  validates :periode, presence: true
end
