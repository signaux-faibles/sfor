class CreateLabelGroups < ActiveRecord::Migration[7.1]
  def change
    create_table :label_groups do |t|
      t.string :name

      t.timestamps
    end
  end
end
