class CreateOsfProcols < ActiveRecord::Migration[7.2]
  def change
    create_table :osf_procols do |t|
      t.string :siret, limit: 14, null: false
      t.date :date_effet
      t.text :action_procol
      t.text :stade_procol

      t.timestamps
    end

    add_index :osf_procols, :siret
    add_index :osf_procols, :date_effet
  end
end
