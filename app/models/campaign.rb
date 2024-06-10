class Campaign < ApplicationRecord
  has_many :campaign_memberships
  has_many :establishments, through: :campaign_memberships
end
