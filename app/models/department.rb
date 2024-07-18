class Department < ApplicationRecord
  has_many :establishments
  has_many :companies

  def self.ransackable_attributes(auth_object = nil)
    ["code", "created_at", "id", "id_value", "name", "updated_at"]
  end
end
