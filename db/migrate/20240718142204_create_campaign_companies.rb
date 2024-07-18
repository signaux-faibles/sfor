class CreateCampaignCompanies < ActiveRecord::Migration[7.1]
  def change
    create_table :campaign_companies do |t|
      t.references :campaign, null: false, foreign_key: true
      t.references :company, null: false, foreign_key: true
      t.string :status

      t.timestamps
    end
  end
end
