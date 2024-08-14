class AddLevelAndDescriptionToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :level, :string, null: false, default: 'A'
    add_column :users, :description, :text
  end
end
