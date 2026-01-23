class AddIndexForSiegeEstablishmentsExcelExport < ActiveRecord::Migration[7.2]
  def change
    # Partial composite index to optimize Excel export siege establishments query
    # Query: WHERE e.siege = true AND e.siren IN (...) ORDER BY e.siren, e.siret
    # This is used in Excel::ListGenerator#load_all_data_in_single_query
    # A partial index is optimal since we only query siege = true establishments
    unless index_exists?(:establishments, %i[siren siege],
                         name: "index_establishments_on_siren_and_siege")
      add_index :establishments, %i[siren siege],
                name: "index_establishments_on_siren_and_siege",
                where: "siege = true"
    end
  end
end
