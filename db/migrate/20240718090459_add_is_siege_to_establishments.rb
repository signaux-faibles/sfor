class AddIsSiegeToEstablishments < ActiveRecord::Migration[7.1]
  def change
    add_column :establishments, :is_siege, :boolean
  end
end
