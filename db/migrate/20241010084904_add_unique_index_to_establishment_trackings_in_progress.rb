class AddUniqueIndexToEstablishmentTrackingsInProgress < ActiveRecord::Migration[7.1]
  def change
    add_index :establishment_trackings,
              [:establishment_id, :state],
              unique: true,
              where: "state = 'in_progress'",
              name: 'index_single_in_progress_per_establishment'
  end
end
