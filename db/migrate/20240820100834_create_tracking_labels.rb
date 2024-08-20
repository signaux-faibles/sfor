class CreateTrackingLabels < ActiveRecord::Migration[7.1]
  def change
    create_table :tracking_labels do |t|
      t.string :name, null: false
      t.boolean :system, default: true, null: false

      t.timestamps
    end
  end
end
