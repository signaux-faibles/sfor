class List < ApplicationRecord
  has_many :company_lists, dependent: :destroy
  # company_lists has siren column, which matches companies.siren
  has_many :companies, -> { distinct }, through: :company_lists, source: :company
  has_many :company_score_entries, foreign_key: :list_name, primary_key: :label, dependent: :destroy

  # validates :label, presence: true, uniqueness: true
  # validates :code, presence: true, uniqueness: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[code created_at id id_value label updated_at]
  end
end
