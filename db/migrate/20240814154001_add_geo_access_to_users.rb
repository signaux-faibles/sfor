class AddGeoAccessToUsers < ActiveRecord::Migration[7.1]
  def change
    add_reference :users, :geo_access, null: false, foreign_key: true
  end
end
