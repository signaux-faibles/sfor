class CreateEstablishmentTrackingSupportingServices < ActiveRecord::Migration[7.1]
  def change
    create_table :establishment_tracking_supporting_services do |t|
      t.references :establishment_tracking, null: false, foreign_key: true
      t.references :supporting_service, null: false, foreign_key: true

      t.timestamps
    end

    add_index :establishment_tracking_supporting_services, 
              [:establishment_tracking_id, :supporting_service_id], 
              unique: true
  end
end
