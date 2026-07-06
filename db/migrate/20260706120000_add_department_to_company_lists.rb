class AddDepartmentToCompanyLists < ActiveRecord::Migration[7.2]
  def change
    add_column :company_lists, :department, :string, limit: 10, default: "", null: false

    add_index :company_lists, %i[list_id department alert],
              name: "index_company_lists_on_list_id_department_alert"
  end
end
