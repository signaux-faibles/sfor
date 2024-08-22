class Department < ApplicationRecord
  belongs_to :region

  has_many :user_departments, dependent: :destroy
  has_many :users, through: :user_departments

  has_many :establishments
  has_many :companies

  validates :name, presence: true
  validates :code, presence: true, uniqueness: true

  def self.ransackable_attributes(auth_object = nil)
    ["code", "created_at", "id", "id_value", "name", "updated_at"]
  end
end
