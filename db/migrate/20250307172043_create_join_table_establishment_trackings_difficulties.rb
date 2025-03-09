class CreateJoinTableEstablishmentTrackingsDifficulties < ActiveRecord::Migration[7.1]
  def change
    create_join_table :establishment_trackings, :difficulties do |t|
      t.index [:establishment_tracking_id, :difficulty_id], unique: true
      t.index [:difficulty_id, :establishment_tracking_id], unique: true
    end
  end
end
