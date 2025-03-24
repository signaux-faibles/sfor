class CreateSupportingServices < ActiveRecord::Migration[7.1]
  def change
    create_table :supporting_services do |t|
      t.string :name, null: false

      t.timestamps
    end
  end
end
