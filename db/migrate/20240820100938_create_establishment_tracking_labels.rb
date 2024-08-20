class CreateEstablishmentTrackingLabels < ActiveRecord::Migration[7.1]
  def change
    create_table :establishment_tracking_labels do |t|
      t.references :establishment_tracking, null: false, foreign_key: true
      t.references :tracking_label, null: false, foreign_key: true

      t.timestamps
    end
  end
end
