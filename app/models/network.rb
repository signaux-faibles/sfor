class Network < ApplicationRecord
  has_many :segments, dependent: :destroy
  has_many :network_memberships, dependent: :destroy
  has_many :users, through: :network_memberships

  validates :name, presence: true, uniqueness: true
end
