class RenameStatusToStateInEstablishmentTrackings < ActiveRecord::Migration[7.1]
  def change
    rename_column :establishment_trackings, :status, :state
  end
end
