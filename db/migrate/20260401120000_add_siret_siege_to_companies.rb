class AddSiretSiegeToCompanies < ActiveRecord::Migration[7.2]
  def change
    add_column :companies, :siret_siege, :string, limit: 14, null: true
  end
end
