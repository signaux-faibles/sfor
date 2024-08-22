class GeoAccess < ApplicationRecord
  has_many :department_geo_accesses, dependent: :destroy
  has_many :departments, through: :department_geo_accesses

  validates :name, presence: true, uniqueness: true
end
