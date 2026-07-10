class RemoveSizeIdFromEstablishmentTrackings < ActiveRecord::Migration[7.2]
  def change
    remove_reference :establishment_trackings, :size, foreign_key: true
  end
end
