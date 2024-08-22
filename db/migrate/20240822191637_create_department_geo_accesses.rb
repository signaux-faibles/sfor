class CreateDepartmentGeoAccesses < ActiveRecord::Migration[7.1]
  def change
    create_table :department_geo_accesses do |t|
      t.references :geo_access, null: false, foreign_key: true
      t.references :department, null: false, foreign_key: true

      t.timestamps
    end
  end
end
