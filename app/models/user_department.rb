class UserDepartment < ApplicationRecord
  belongs_to :user
  belongs_to :department

  validates :user_id, uniqueness: { scope: :department_id }
end
