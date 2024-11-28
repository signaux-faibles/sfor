class CreateEstablishmentTrackingSectors < ActiveRecord::Migration[7.1]
  def change
    create_table :establishment_tracking_sectors do |t|
      t.references :establishment_tracking, null: false, foreign_key: true
      t.references :sector, null: false, foreign_key: true

      t.timestamps
    end
  end
end
