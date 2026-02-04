class Establishment < ApplicationRecord
  belongs_to :company, foreign_key: :siren, primary_key: :siren, optional: false
  belongs_to :department, foreign_key: :departement, primary_key: :code, optional: false

  # Return the reason sociale from the company, fallback to siret
  def raison_sociale
    company&.raison_sociale || siret
  end

  has_many :establishment_trackings, foreign_key: :establishment_siret, primary_key: :siret, dependent: :destroy
  has_many :contacts, foreign_key: :establishment_siret, primary_key: :siret, dependent: :destroy
  has_many :osf_aps, foreign_key: :siret, primary_key: :siret, dependent: :destroy
  has_many :osf_cotisations, foreign_key: :siret, primary_key: :siret, dependent: :destroy
  has_many :osf_delais, foreign_key: :siret, primary_key: :siret, dependent: :destroy
  has_many :osf_debits, foreign_key: :siret, primary_key: :siret, dependent: :destroy

  validates :siren, presence: true, length: { is: 9 }
  validates :siret, presence: true, length: { is: 14 }, uniqueness: { scope: :siren }

  def self.ransackable_attributes(_auth_object = nil)
    %w[
      siren siret siege code_commune departement ape code_activite
      address date_creation longitude latitude is_active created_at updated_at
    ]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[company department establishment_trackings contacts osf_aps osf_cotisations osf_delais osf_debits]
  end

  def to_param
    siret
  end
end
