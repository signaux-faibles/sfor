class CreateOsfEntEffectifs < ActiveRecord::Migration[7.2]
  def change
    create_table :osf_ent_effectifs do |t|
      t.string :siren, limit: 9, null: false
      t.date :periode, null: false
      t.integer :effectif

      t.timestamps
    end

    add_index :osf_ent_effectifs, :siren
    add_index :osf_ent_effectifs, :periode
    add_index :osf_ent_effectifs, [:siren, :periode]
  end
end
