class AddNafSectionToCompanies < ActiveRecord::Migration[7.2]
  def change
    add_column :companies, :naf_section, :string, limit: 1
  end
end
