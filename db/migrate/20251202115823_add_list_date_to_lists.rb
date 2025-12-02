class AddListDateToLists < ActiveRecord::Migration[7.2]
  def change
    add_column :lists, :list_date, :date
  end
end

