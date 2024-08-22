class DropUserRegions < ActiveRecord::Migration[7.1]
  def up
    drop_table :user_regions
  end

  def down
    create_table :user_departments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :region, null: false, foreign_key: true

      t.timestamps
    end
  end
end
