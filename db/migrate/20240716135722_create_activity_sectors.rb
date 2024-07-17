class CreateActivitySectors < ActiveRecord::Migration[7.1]
  def change
    create_table :activity_sectors do |t|
      t.integer :depth, null: false
      t.string :code, null: false
      t.string :libelle, null: false
      t.integer :parent_id, index: true
      t.integer :level_one_id, index: true

      t.timestamps
    end

    add_index :activity_sectors, :code, unique: true
    add_foreign_key :activity_sectors, :activity_sectors, column: :parent_id
    add_foreign_key :activity_sectors, :activity_sectors, column: :level_one_id
  end
end
