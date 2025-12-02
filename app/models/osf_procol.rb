class OsfProcol < ApplicationRecord
  belongs_to :company, foreign_key: :siren, primary_key: :siren, optional: true
  belongs_to :establishment, foreign_key: :siret, primary_key: :siret, optional: true

  validates :siren, presence: true, length: { is: 9 }
  validates :siret, presence: true, length: { is: 14 }
end
