class AddActivitySectorToEstablishments < ActiveRecord::Migration[7.1]
  def change
    add_reference :establishments, :activity_sector, foreign_key: true
  end
end
