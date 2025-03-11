class CreateJoinTableEstablishmentTrackingsCodefiRedirects < ActiveRecord::Migration[7.1]
  def change
    create_join_table :establishment_trackings, :codefi_redirects do |t|
      t.index [:establishment_tracking_id, :codefi_redirect_id], unique: true
      t.index [:codefi_redirect_id, :establishment_tracking_id], unique: true
    end
  end
end
