class AddDepartmentToCompanies < ActiveRecord::Migration[7.1]
  def change
    add_reference :companies, :department, null: false, foreign_key: true
  end
end
