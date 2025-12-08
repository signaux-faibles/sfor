class ChangeNafCodeLimitInCompanies < ActiveRecord::Migration[7.2]
  def change
    change_column :companies, :naf_code, :string, limit: 6
  end
end
