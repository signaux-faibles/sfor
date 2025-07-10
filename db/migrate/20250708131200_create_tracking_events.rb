class CreateTrackingEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :tracking_events do |t|
      t.references :establishment_tracking, null: false, foreign_key: true
      t.references :triggered_by_user, null: false, foreign_key: { to_table: :users }
      
      # Event metadata
      t.string :event_type, null: false # 'creation', 'state_change', 'labels_change', 'referents_change', 'participants_change', etc.
      t.text :description # Human readable description
      t.json :changes_summary # Store what actually changed for debugging
      
      t.timestamps
    end
    
    add_index :tracking_events, :event_type
    add_index :tracking_events, :created_at
    add_index :tracking_events, [:establishment_tracking_id, :created_at]
  end
end
