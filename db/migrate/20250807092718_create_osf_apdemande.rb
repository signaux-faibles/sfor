class CreateOsfApdemande < ActiveRecord::Migration[7.2]
  def change
    create_table :osf_apdemandes, id: false do |t|
      t.string :id_demande, limit: 11, primary_key: true
      t.string :siret, limit: 14
      t.integer :effectif_entreprise
      t.integer :effectif
      t.date :date_statut
      t.date :periode_debut
      t.date :periode_fin
      t.float :hta
      t.float :mta
      t.integer :effectif_autorise
      t.integer :motif_recours_se
      t.float :heures_consommees
      t.float :montant_consomme
      t.integer :effectif_consomme
      t.integer :perimetre

      t.timestamps
    end
    add_index :osf_apdemandes, :siret
  end
end
