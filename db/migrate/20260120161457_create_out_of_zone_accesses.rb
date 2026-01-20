class CreateOutOfZoneAccesses < ActiveRecord::Migration[7.2]
  def change
    create_table :out_of_zone_accesses do |t|
      t.datetime :accessed_at, null: false
      t.string :user_email, null: false
      t.string :user_geo_zone, null: false
      t.string :resource_department, null: false
      t.string :user_segment, null: false
      t.text :accessed_url, null: false
      t.string :resource_type, null: false
      t.string :resource_identifier, null: false

      t.timestamps
    end

    add_index :out_of_zone_accesses, :accessed_at
    add_index :out_of_zone_accesses, :user_email
    add_index :out_of_zone_accesses, :resource_department
    add_index :out_of_zone_accesses, :user_segment
  end
end
