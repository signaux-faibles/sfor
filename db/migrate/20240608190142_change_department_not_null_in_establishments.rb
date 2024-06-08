class ChangeDepartmentNotNullInEstablishments < ActiveRecord::Migration[7.1]
  def change
    change_column_null :establishments, :department_id, false
  end
end
