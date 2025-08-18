class CreateOsfApconso < ActiveRecord::Migration[7.2]
  def change
    create_table :osf_apconsos do |t|
      t.string :siret, limit: 14
      t.string :id_demande, limit: 11
      t.float :heures_consommees
      t.float :montant
      t.integer :effectif
      t.date :periode

      t.timestamps
    end
    add_index :osf_apconsos, :siret
    add_index :osf_apconsos, :id_demande
  end
end
