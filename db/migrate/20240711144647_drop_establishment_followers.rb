class DropEstablishmentFollowers < ActiveRecord::Migration[7.1]
  def change
    drop_table :establishment_followers do |t|
      t.bigint "user_id", null: false
      t.bigint "establishment_id", null: false
      t.date "start_date"
      t.date "end_date"
      t.string "status"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end
  end
end