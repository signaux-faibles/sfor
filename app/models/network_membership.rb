class NetworkMembership < ApplicationRecord
  belongs_to :user
  belongs_to :network

  validates :user_id, uniqueness: { scope: :network_id, message: "is already a member of this network" }
end
