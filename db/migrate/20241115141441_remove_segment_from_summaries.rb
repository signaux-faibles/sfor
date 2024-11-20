class RemoveSegmentFromSummaries < ActiveRecord::Migration[7.1]
  def change
    remove_index :summaries, column: :establishment_tracking_id, name: 'index_unique_codefi_summary', if_exists: true
    remove_index :summaries, column: [:establishment_tracking_id, :segment_id], name: 'index_unique_segment_summary', if_exists: true

    remove_reference :summaries, :segment, foreign_key: true
  end
end
