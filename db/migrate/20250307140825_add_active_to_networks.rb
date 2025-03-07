class AddActiveToNetworks < ActiveRecord::Migration[7.1]
  def change
    add_column :networks, :active, :boolean, default: false, null: false
  end
end
