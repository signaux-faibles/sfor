class CreateSjcfCompanies < ActiveRecord::Migration[7.2]
  def change
    create_table :sjcf_companies do |t|
      t.string :siren, limit: 9, null: false
      t.string :libelle_liste, null: false

      t.timestamps
    end

    add_index :sjcf_companies, :siren
    add_index :sjcf_companies, :libelle_liste
    add_index :sjcf_companies, [:siren, :libelle_liste], unique: true
  end
end
