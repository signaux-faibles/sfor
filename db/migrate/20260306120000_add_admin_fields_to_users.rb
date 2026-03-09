class AddAdminFieldsToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :ambassador, :boolean, default: false, null: false
    add_column :users, :trained, :boolean, default: false, null: false
    add_column :users, :feedbacks, :text
    add_column :users, :last_contact, :date
  end
end
