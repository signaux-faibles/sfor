class RenameActionToUserAction < ActiveRecord::Migration[7.1]
  def change
    rename_table :actions, :user_actions

    rename_column :establishment_tracking_actions, :action_id, :user_action_id
  end
end
