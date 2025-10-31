class Establishment < ApplicationRecord
  belongs_to :company, foreign_key: :siren, primary_key: :siren, optional: false
  belongs_to :department, foreign_key: :departement, primary_key: :code, optional: false

  # Return the reason sociale from the company, fallback to siret
  def raison_sociale
    company&.raison_sociale || siret
  end

  has_many :establishment_trackings, foreign_key: :establishment_siret, primary_key: :siret, dependent: :destroy
  has_many :contacts, dependent: :destroy
  has_many :osf_aps, foreign_key: :siret, primary_key: :siret, dependent: :destroy

  validates :siren, presence: true, length: { is: 9 }
  validates :siret, presence: true, length: { is: 14 }, uniqueness: { scope: :siren }

  def self.ransackable_attributes(_auth_object = nil)
    %w[
      siren siret siege complement_adresse numero_voie indrep
      type_voie voie commune commune_etranger distribution_speciale
      code_commune code_cedex cedex code_pays_etranger pays_etranger
      code_postal departement ape code_activite nomenclature_activite
      date_creation longitude latitude created_at updated_at
    ]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[establishment_trackings contacts osf_aps]
  end

  def to_param
    siret
  end
end
