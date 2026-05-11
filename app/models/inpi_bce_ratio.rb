class InpiBceRatio < ApplicationRecord
  belongs_to :company, foreign_key: :siren, primary_key: :siren, optional: false

  validates :siren, presence: true, length: { is: 9 }
  validates :date_cloture_exercice, presence: true
  validates :type_bilan, presence: true, length: { maximum: 1 }
  validates :siren, uniqueness: { scope: %i[date_cloture_exercice type_bilan] }
end
