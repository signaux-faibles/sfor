class AddCurrentProcolStatusToCompanies < ActiveRecord::Migration[7.2]
  def change
    add_column :companies, :current_procol_status, :string
  end
end
