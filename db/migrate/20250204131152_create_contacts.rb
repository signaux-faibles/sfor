class CreateContacts < ActiveRecord::Migration[7.1]
  def change
    create_table :contacts do |t|
      t.references :establishment, null: false, foreign_key: true
      t.string :first_name
      t.string :last_name
      t.string :role
      t.string :phone_number_primary
      t.string :phone_number_secondary
      t.string :email
      t.datetime :discarded_at

      t.timestamps
    end
  end
end
