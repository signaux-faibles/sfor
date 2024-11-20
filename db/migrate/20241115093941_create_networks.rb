class CreateNetworks < ActiveRecord::Migration[7.1]
  def change
    create_table :networks do |t|
      t.string :name, null: false

      t.timestamps
    end

    add_reference :segments, :network, foreign_key: true, null: false

    create_table :network_memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :network, null: false, foreign_key: true

      t.timestamps
    end

    add_index :network_memberships, [:user_id, :network_id], unique: true
  end
end
