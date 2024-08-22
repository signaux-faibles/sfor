class CreateDepartments < ActiveRecord::Migration[7.1]
  def change
    create_table :departments do |t|
      t.string :code
      t.string :name

      t.timestamps
    end

    add_index :departments, :name, unique: true
  end
end
