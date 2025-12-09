class AddDepartmentCodeToCompanies < ActiveRecord::Migration[7.2]
  def change
    add_column :companies, :department, :string, limit: 10, null: false, default: ""
    add_index :companies, :department
  end
end
