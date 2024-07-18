class CreateLists < ActiveRecord::Migration[7.1]
  def change
    create_table :lists do |t|
      t.string :label, null: false
      t.string :code, null: false

      t.timestamps
    end
  end
end
