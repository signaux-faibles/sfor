class CampaignMembership < ApplicationRecord
  belongs_to :campaign
  belongs_to :establishment
end
