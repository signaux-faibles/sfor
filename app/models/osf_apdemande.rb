class OsfApdemande < ApplicationRecord
  self.primary_key = :id_demande

  belongs_to :establishment, foreign_key: :siret, primary_key: :siret
  has_many :osf_apconsos, foreign_key: :id_demande, primary_key: :id_demande, dependent: :destroy

  validates :id_demande, presence: true, length: { is: 11 }
  validates :siret, presence: true, length: { is: 14 }
end
