class CreateEstablishmentFollowers < ActiveRecord::Migration[7.1]
  def change
    create_table :establishment_followers do |t|
      t.references :user, null: false, foreign_key: true
      t.references :establishment, null: false, foreign_key: true
      t.date :start_date
      t.date :end_date
      t.string :status

      t.timestamps
    end
  end
end
