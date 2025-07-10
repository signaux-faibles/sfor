class CreateEstablishmentTrackingSnapshots < ActiveRecord::Migration[7.1]
  def change
    create_table :establishment_tracking_snapshots do |t|
      # Original tracking reference
      t.references :original_tracking, null: false, foreign_key: { to_table: :establishment_trackings }
      t.references :tracking_event, null: false, foreign_key: true

      t.string :creator_email
      
      t.string :state, null: false
      t.date :start_date
      t.date :end_date
      t.string :criticality_name
      t.text :label_names, array: true, default: []
      t.text :supporting_service_names, array: true, default: []
      t.text :difficulty_names, array: true, default: []
      t.text :user_action_names, array: true, default: []
      t.text :codefi_redirect_names, array: true, default: []
      t.string :size_name
      t.text :sector_names, array: true, default: []
      t.text :referent_emails, array: true, default: []
      t.text :participant_emails, array: true, default: []
      t.text :referent_segment_names, array: true, default: []
      t.text :participant_segment_names, array: true, default: []
      t.text :referent_entity_names, array: true, default: []
      t.text :participant_entity_names, array: true, default: []
      
      t.string :establishment_siret
      t.string :establishment_department_code
      t.string :establishment_department_name
      t.string :establishment_region_code
      t.string :establishment_region_name
      
      t.timestamps
    end
    
    add_index :establishment_tracking_snapshots, :state
    
    add_index :establishment_tracking_snapshots, :label_names, using: :gin
    add_index :establishment_tracking_snapshots, :referent_emails, using: :gin
    add_index :establishment_tracking_snapshots, :participant_emails, using: :gin
  end
end
