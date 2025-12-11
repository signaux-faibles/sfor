class SjcfCompany < ApplicationRecord
  validates :siren, presence: true, length: { is: 9 }
  validates :libelle_liste, presence: true
  validates :siren, uniqueness: { scope: :libelle_liste }
end
