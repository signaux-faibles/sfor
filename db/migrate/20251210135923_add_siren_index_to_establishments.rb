class AddSirenIndexToEstablishments < ActiveRecord::Migration[7.2]
  def change
    add_index :establishments, :siren
  end
end
