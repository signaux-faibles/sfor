class AddIsLastToOsfAps < ActiveRecord::Migration[7.2]
  def change
    add_column :osf_aps, :is_last, :boolean
  end
end
