class AddCascadeDeleteToCompanyListsFk < ActiveRecord::Migration[7.2]
  def change
    remove_foreign_key :company_lists, :lists
    add_foreign_key :company_lists, :lists, on_delete: :cascade
  end
end
