class AddScoreAndAlertToCompanyLists < ActiveRecord::Migration[7.2]
  def change
    add_column :company_lists, :score, :decimal, precision: 20, scale: 10
    add_column :company_lists, :alert, :string

    add_index :company_lists, [:list_id, :score],
              name: "index_company_lists_on_list_id_and_score"
  end
end
