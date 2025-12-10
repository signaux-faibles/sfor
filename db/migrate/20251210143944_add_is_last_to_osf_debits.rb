class AddIsLastToOsfDebits < ActiveRecord::Migration[7.2]
  def change
    add_column :osf_debits, :is_last, :boolean
  end
end
