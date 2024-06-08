class AddDepartmentToEstablishments < ActiveRecord::Migration[7.1]
  def change
    add_reference :establishments, :department, null: true, foreign_key: true
  end
end
