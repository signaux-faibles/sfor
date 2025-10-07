class CreateOsfEffectifs < ActiveRecord::Migration[7.2]
  def change
    create_table :osf_effectifs do |t|
      t.string :siret, limit: 14, null: false
      t.date :periode, null: false
      t.integer :effectif

      t.timestamps
    end

    add_index :osf_effectifs, :siret
    add_index :osf_effectifs, :periode
    add_index :osf_effectifs, [:siret, :periode]
  end
end
