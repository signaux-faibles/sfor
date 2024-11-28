class AddSizeAndCriticalityToEstablishmentTrackings < ActiveRecord::Migration[7.1]
  def change
    add_reference :establishment_trackings, :size, null: true, foreign_key: true
    add_reference :establishment_trackings, :criticality, null: true, foreign_key: true
  end
end
