class CreateEstablishmentTrackings < ActiveRecord::Migration[7.1]
  def change
    create_table :establishment_trackings do |t|
      t.references :creator, null: false, foreign_key: { to_table: :users }
      t.references :establishment, null: false, foreign_key: true
      t.date :start_date
      t.date :end_date
      t.string :status

      t.timestamps
    end
  end
end
