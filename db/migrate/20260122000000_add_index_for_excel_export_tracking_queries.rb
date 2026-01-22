class AddIndexForExcelExportTrackingQueries < ActiveRecord::Migration[7.2]
  # Migration timestamp: 20260122000000
  # This migration adds an index to optimize Excel export batch loading queries
  def change
    # Index for Excel export batch loading of tracking statuses
    # Query: WHERE establishment_siret IN (...) AND discarded_at IS NULL
    # This is used in Excel::ListGenerator#preload_tracking_statuses
    # A partial index is optimal since we only query non-discarded records (.kept scope)
    unless index_exists?(:establishment_trackings, %i[establishment_siret discarded_at],
                         name: "index_establishment_trackings_on_siret_and_discarded_at")
      add_index :establishment_trackings, %i[establishment_siret discarded_at],
                name: "index_establishment_trackings_on_siret_and_discarded_at",
                where: "discarded_at IS NULL"
    end
  end
end
