class CreateOsfCotisations < ActiveRecord::Migration[7.2]
  def change
    create_table :osf_cotisations do |t|
      t.string :siret, limit: 14, null: false
      t.date :periode, null: false
      t.decimal :du, precision: 15, scale: 2

      t.timestamps
    end

    add_index :osf_cotisations, :siret
    add_index :osf_cotisations, :periode
    add_index :osf_cotisations, [:siret, :periode]
  end
end
