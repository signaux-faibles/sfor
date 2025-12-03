class AddNafCodeToCompanies < ActiveRecord::Migration[7.2]
  def change
    add_column :companies, :naf_code, :string, limit: 5
    add_index :companies, :naf_code
  end
end
