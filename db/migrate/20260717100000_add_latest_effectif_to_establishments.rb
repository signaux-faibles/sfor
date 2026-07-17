class AddLatestEffectifToEstablishments < ActiveRecord::Migration[7.2]
  def change
    add_column :establishments, :latest_effectif, :integer
  end
end
