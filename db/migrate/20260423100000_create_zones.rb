class CreateZones < ActiveRecord::Migration[7.2]
  def change
    create_table :zones do |t|
      t.string :key, null: false
      t.text :content, null: false

      t.timestamps
    end

    add_index :zones, :key, unique: true
  end
end
