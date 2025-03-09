class CreateDifficulties < ActiveRecord::Migration[7.1]
  def change
    create_table :difficulties do |t|
      t.string :name, null: false

      t.timestamps
    end
    add_index :difficulties, :name, unique: true
  end
end
