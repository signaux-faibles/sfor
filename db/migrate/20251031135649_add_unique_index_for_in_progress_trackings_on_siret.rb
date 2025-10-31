class AddUniqueIndexForInProgressTrackingsOnSiret < ActiveRecord::Migration[7.2]
  def up
    # Drop old unique index if it exists (might be on establishment_id)
    execute <<-SQL
      DROP INDEX IF EXISTS index_single_in_progress_per_establishment;
    SQL
    
    # Create new unique index on establishment_siret + state
    add_index :establishment_trackings,
              [:establishment_siret, :state],
              unique: true,
              where: "state = 'in_progress'",
              name: 'index_single_in_progress_per_establishment'
  end

  def down
    execute <<-SQL
      DROP INDEX IF EXISTS index_single_in_progress_per_establishment;
    SQL
  end
end
