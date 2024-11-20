class AddUniqueIndexToSummaries < ActiveRecord::Migration[7.1]
  def change
    add_index :summaries, [:establishment_tracking_id, :network_id], unique: true, name: 'index_unique_network_summary'
  end
end
