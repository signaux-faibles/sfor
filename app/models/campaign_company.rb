class CampaignCompany < ApplicationRecord
  belongs_to :campaign
  belongs_to :company
end
