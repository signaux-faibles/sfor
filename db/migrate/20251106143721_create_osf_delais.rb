class CreateOsfDelais < ActiveRecord::Migration[7.2]
  def change
    create_table :osf_delais do |t|
      t.string :siret, limit: 14, null: false
      t.date :date_creation
      t.date :date_echeance
      t.integer :duree_delai
      t.decimal :montant_echeancier, precision: 15, scale: 2
      t.string :stade, limit: 50
      t.string :action, limit: 50

      t.timestamps
    end

    add_index :osf_delais, :siret
    add_index :osf_delais, :date_creation
    add_index :osf_delais, :date_echeance
  end
end
