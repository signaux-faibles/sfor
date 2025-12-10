class AddIsActiveToEstablishments < ActiveRecord::Migration[7.2]
  def change
    add_column :establishments, :is_active, :boolean, default: false, null: false
  end
end
