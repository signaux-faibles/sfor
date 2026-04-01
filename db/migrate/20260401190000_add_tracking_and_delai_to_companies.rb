class AddTrackingAndDelaiToCompanies < ActiveRecord::Migration[7.2]
  def change
    add_column :companies, :tracking_status, :string
    add_column :companies, :delai_urssaf_until, :date
  end
end
