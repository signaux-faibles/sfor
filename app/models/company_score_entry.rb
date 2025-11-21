class CompanyScoreEntry < ApplicationRecord
  belongs_to :company, foreign_key: :siren, primary_key: :siren, optional: false
  belongs_to :list, foreign_key: :list_name, primary_key: :label, optional: false

  validates :siren, presence: true, length: { is: 9 }
  validates :list_name, presence: true
  validates :siren, uniqueness: { scope: %i[list_name periode] }

  def self.ransackable_attributes(_auth_object = nil)
    %w[
      siren code_naf score code_commune region alert batch algo periode
      seuil_modere seuil_fort macro_expl micro_expl created_at updated_at
    ]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[company list]
  end
end
