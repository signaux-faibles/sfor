class AddLatestEffectifToCompanies < ActiveRecord::Migration[7.2]
  def change
    add_column :companies, :latest_effectif, :integer
  end
end
