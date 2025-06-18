class AddDiscardedAtToTrackingLabels < ActiveRecord::Migration[7.2]
  def change
    add_column :tracking_labels, :discarded_at, :datetime
    add_index :tracking_labels, :discarded_at
  end
end
