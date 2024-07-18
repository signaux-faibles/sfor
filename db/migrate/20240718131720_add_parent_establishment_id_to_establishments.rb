class AddParentEstablishmentIdToEstablishments < ActiveRecord::Migration[7.1]
  def change
    add_column :establishments, :parent_establishment_id, :integer
    add_foreign_key :establishments, :establishments, column: :parent_establishment_id
    add_index :establishments, :parent_establishment_id
  end
end
