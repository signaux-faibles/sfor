class CreateTrackingReferents < ActiveRecord::Migration[7.1]
  def change
    create_table :tracking_referents do |t|
      t.references :establishment_tracking, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
