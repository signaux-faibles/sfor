class AddRegionToDepartments < ActiveRecord::Migration[7.1]
  def change
    add_reference :departments, :region, null: false, foreign_key: true
  end
end
