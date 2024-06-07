class CreateCampaignMemberships < ActiveRecord::Migration[7.1]
  def change
    create_table :campaign_memberships do |t|
      t.references :campaign, null: false, foreign_key: true
      t.references :establishment, null: false, foreign_key: true
      t.string :status

      t.timestamps
    end
  end
end
