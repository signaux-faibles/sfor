class CreateImports < ActiveRecord::Migration[7.2]
  def change
    create_table :imports do |t|
      t.string :name
      t.date :import_date
      t.date :data_freshness

      t.timestamps
    end
  end
end
