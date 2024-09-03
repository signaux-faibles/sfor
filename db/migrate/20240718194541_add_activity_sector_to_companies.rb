class AddActivitySectorToCompanies < ActiveRecord::Migration[7.1]
  def change
    add_reference :companies, :activity_sector, foreign_key: true
  end
end
