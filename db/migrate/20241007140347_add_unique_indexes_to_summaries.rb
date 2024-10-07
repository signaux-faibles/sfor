class AddUniqueIndexesToSummaries < ActiveRecord::Migration[7.1]
  def change
    remove_index :summaries, column: [:establishment_tracking_id, :segment_id], if_exists: true

    add_index :summaries, :establishment_tracking_id, unique: true, where: 'segment_id IS NULL', name: 'index_unique_codefi_summary'

    add_index :summaries, [:establishment_tracking_id, :segment_id], unique: true, where: 'segment_id IS NOT NULL', name: 'index_unique_segment_summary'
  end
end
