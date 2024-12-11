class AddModifiedAtToEstablishmentTrackings < ActiveRecord::Migration[7.1]
  def change
    add_column :establishment_trackings, :modified_at, :date
  end
end
