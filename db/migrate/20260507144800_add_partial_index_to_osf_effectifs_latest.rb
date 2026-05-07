class AddPartialIndexToOsfEffectifsLatest < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_index :osf_effectifs, :siret,
              where: "is_latest = true",
              name: "idx_osf_effectifs_siret_latest",
              algorithm: :concurrently
  end
end
