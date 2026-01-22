class AddCompositeIndexToOsfProcolsForExcelExport < ActiveRecord::Migration[7.2]
  def change
    # Composite index to optimize Excel export procol status queries
    # Query: WHERE siren IN (...) AND date_effet <= ?
    # This is used in Excel::ListGenerator#preload_procol_statuses
    # The composite index allows efficient filtering by both siren and date_effet together
    unless index_exists?(:osf_procols, %i[siren date_effet],
                         name: "index_osf_procols_on_siren_and_date_effet")
      add_index :osf_procols, %i[siren date_effet],
                name: "index_osf_procols_on_siren_and_date_effet"
    end
  end
end
