class AddIndexToOsfProcolsForProcolStatusDistinctOn < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    # Supports DISTINCT ON (siren, action_procol) ... ORDER BY siren, action_procol, date_effet DESC
    # used by companies:update_procol_status and procol_at_date().
    unless index_exists?(:osf_procols, %i[siren action_procol date_effet],
                         name: "index_osf_procols_on_siren_action_procol_date_effet")
      add_index :osf_procols, %i[siren action_procol date_effet],
                order: { date_effet: :desc },
                name: "index_osf_procols_on_siren_action_procol_date_effet",
                algorithm: :concurrently
    end
  end
end
