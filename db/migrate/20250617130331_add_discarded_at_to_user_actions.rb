class AddDiscardedAtToUserActions < ActiveRecord::Migration[7.2]
  def change
    add_column :user_actions, :discarded_at, :datetime
    add_index :user_actions, :discarded_at
  end
end
