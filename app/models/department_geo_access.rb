class DepartmentGeoAccess < ApplicationRecord
  belongs_to :geo_access
  belongs_to :department

  validates :geo_access_id, uniqueness: { scope: :department_id }
end
