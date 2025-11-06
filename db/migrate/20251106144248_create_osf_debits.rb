class CreateOsfDebits < ActiveRecord::Migration[7.2]
  def change
    create_table :osf_debits do |t|
      t.string :siret, limit: 14, null: false
      t.date :periode, null: false
      t.decimal :part_ouvriere, precision: 15, scale: 2
      t.decimal :part_patronale, precision: 15, scale: 2

      t.timestamps
    end

    add_index :osf_debits, :siret
    add_index :osf_debits, :periode
    add_index :osf_debits, [:siret, :periode]
  end
end
