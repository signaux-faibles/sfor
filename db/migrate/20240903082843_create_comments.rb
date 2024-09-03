class CreateComments < ActiveRecord::Migration[7.1]
  def change
    create_table :comments do |t|
      t.text :content
      t.references :establishment_tracking, null: false, foreign_key: true
      t.references :segment, foreign_key: true, null: true

      t.timestamps
    end
  end
end
