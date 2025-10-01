class CreateOsfAp < ActiveRecord::Migration[7.2]
  def change
    create_table :osf_aps do |t|
      t.string :siret, limit: 14, null: false
      t.string :siren, limit: 9, null: false
      t.date :periode, null: false
      t.float :etp_autorise
      t.float :etp_consomme
      t.text :motif_recours

      t.timestamps
    end
    
    add_index :osf_aps, :siret
    add_index :osf_aps, :siren
    add_index :osf_aps, :periode
    add_index :osf_aps, [:siret, :periode]
  end
end
