class AddIsLatestToOsfEntEffectifs < ActiveRecord::Migration[7.2]
  def change
    add_column :osf_ent_effectifs, :is_latest, :boolean
  end
end
