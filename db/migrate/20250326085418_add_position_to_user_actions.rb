class AddPositionToUserActions < ActiveRecord::Migration[7.1]
  def change
    add_column :user_actions, :position, :integer, null: false, default: 0
  end
end
