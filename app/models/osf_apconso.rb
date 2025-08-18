class OsfApconso < ApplicationRecord
  belongs_to :establishment, foreign_key: :siret, primary_key: :siret
  belongs_to :osf_apdemande, foreign_key: :id_demande, primary_key: :id_demande

  validates :siret, presence: true, length: { is: 14 }
  validates :id_demande, presence: true, length: { is: 11 }
  validates :heures_consommees, :montant, :effectif, :periode, presence: true
end
