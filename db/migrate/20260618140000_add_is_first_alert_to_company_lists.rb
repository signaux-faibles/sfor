# frozen_string_literal: true

class AddIsFirstAlertToCompanyLists < ActiveRecord::Migration[7.2]
  def up
    add_column :company_lists, :is_first_alert, :boolean, default: false, null: false

    add_index :company_lists, %i[list_id is_first_alert],
              where: "is_first_alert = true",
              name: "index_company_lists_on_list_id_first_alert"

    say_with_time "Backfilling company_lists.is_first_alert" do
      List.find_each do |list|
        CompanyLists::FirstAlertComputer.backfill_list!(list)
      end
    end
  end

  def down
    remove_index :company_lists, name: "index_company_lists_on_list_id_first_alert"
    remove_column :company_lists, :is_first_alert
  end
end
