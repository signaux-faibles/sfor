class CreateRegions < ActiveRecord::Migration[7.1]
  def change
    create_table :regions do |t|
      t.string :code, null: false
      t.string :libelle, null: false

      t.timestamps
    end
  end
end
