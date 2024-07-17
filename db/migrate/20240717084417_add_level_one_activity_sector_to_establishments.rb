class AddLevelOneActivitySectorToEstablishments < ActiveRecord::Migration[7.1]
  def change
    add_reference :establishments, :level_one_activity_sector, foreign_key: { to_table: :activity_sectors }
  end
end
