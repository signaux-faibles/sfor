class AddUniqueIndexToEstablishmentsSiret < ActiveRecord::Migration[7.1]
  def change
    add_index :establishments, :siret, unique: true
  end
end
