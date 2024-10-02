class AddDiscardedAtToEstablishmentTrackings < ActiveRecord::Migration[7.1]
  def change
    add_column :establishment_trackings, :discarded_at, :datetime
    add_index :establishment_trackings, :discarded_at
  end
end
