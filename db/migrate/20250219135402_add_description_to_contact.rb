class AddDescriptionToContact < ActiveRecord::Migration[7.1]
  def change
    add_column :contacts, :description, :text
  end
end
