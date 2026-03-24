class AddShowAsFlashToNotifications < ActiveRecord::Migration[7.1]
  def change
    add_column :notifications, :show_as_flash, :string
  end
end
