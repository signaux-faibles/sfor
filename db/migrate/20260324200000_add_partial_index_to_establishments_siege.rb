class AddPartialIndexToEstablishmentsSiege < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_index :establishments, :siren,
              where: "siege = true",
              name: "index_establishments_on_siren_where_siege",
              algorithm: :concurrently
  end
end
