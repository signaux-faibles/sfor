class CreateGeoAccesses < ActiveRecord::Migration[7.1]
  def change
    create_table :geo_accesses do |t|
      t.string :name

      t.timestamps
    end
  end
end
