class CompanyScoreEntry < ApplicationRecord
  belongs_to :company
  belongs_to :list

  validates :siren, presence: true, length: { is: 9 }

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
