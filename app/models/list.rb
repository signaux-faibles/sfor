class List < ApplicationRecord
  has_many :company_lists, dependent: :destroy
  has_many :companies, through: :company_lists

  # validates :label, presence: true, uniqueness: true
  # validates :code, presence: true, uniqueness: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[code created_at id id_value label updated_at]
  end
end
