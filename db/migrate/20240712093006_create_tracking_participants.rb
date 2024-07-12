class CreateTrackingParticipants < ActiveRecord::Migration[7.1]
  def change
    create_table :tracking_participants do |t|
      t.references :user, null: false, foreign_key: true
      t.references :establishment_tracking, null: false, foreign_key: true

      t.timestamps
    end
  end
end
