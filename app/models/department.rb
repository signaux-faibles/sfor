class Department < ApplicationRecord
  belongs_to :region

  has_many :department_geo_accesses, dependent: :destroy
  has_many :geo_accesses, through: :department_geo_accesses

  has_many :establishments
  has_many :companies

  validates :name, presence: true
  validates :code, presence: true, uniqueness: true

  def self.ransackable_attributes(auth_object = nil)
    ["code", "created_at", "id", "id_value", "name", "updated_at"]
  end
end
