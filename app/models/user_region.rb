class UserRegion < ApplicationRecord
  belongs_to :user
  belongs_to :region

  validates :user_id, uniqueness: { scope: :region_id }
end
