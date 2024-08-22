class Region < ApplicationRecord
  has_many :departments, dependent: :destroy

  has_many :user_regions, dependent: :destroy
  has_many :users, through: :user_regions

  validates :code, presence: true, uniqueness: true
  validates :libelle, presence: true
end
