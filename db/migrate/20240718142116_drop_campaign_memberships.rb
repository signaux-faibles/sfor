class DropCampaignMemberships < ActiveRecord::Migration[7.1]
  def change
    drop_table :campaign_memberships
  end
end
