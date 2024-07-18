class List < ApplicationRecord
  has_many :company_lists
  has_many :companies, through: :company_lists

  validates :label, presence: true, uniqueness: true
  validates :code, presence: true, uniqueness: true

  def self.ransackable_attributes(auth_object = nil)
    ["code", "created_at", "id", "id_value", "label", "updated_at"]
  end
end
