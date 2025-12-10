class AddIsLatestToOsfEffectifs < ActiveRecord::Migration[7.2]
  def change
    add_column :osf_effectifs, :is_latest, :boolean
  end
end
