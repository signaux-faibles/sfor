class CreateSummaries < ActiveRecord::Migration[7.1]
  def change
    create_table :summaries do |t|
      t.text :content
      t.references :establishment_tracking, null: false, foreign_key: true
      t.references :segment, foreign_key: true, null: true

      t.timestamps
    end

    add_index :summaries, [:establishment_tracking_id, :segment_id], unique: true
  end
end
