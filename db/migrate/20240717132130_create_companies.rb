class CreateCompanies < ActiveRecord::Migration[7.1]
  def change
    create_table :companies do |t|
      t.string :siren, null: false
      t.string :siret, null: false
      t.string :raison_sociale, null: false
      t.integer :effectif, null: true

      t.timestamps
    end

    add_index :companies, :siren, unique: true
    add_index :companies, :siret, unique: true
  end
end
