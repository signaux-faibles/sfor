# app/services/osf/apdemande_sync_service.rb
# Service to synchronize apdemande data from distant database

module Osf
  class ApdemandeSyncService < BaseOsfSyncService
    BATCH_SIZE = 1000 # Process in chunks of 1000 records

    protected

    def log_file_name
      "osf_apdemande_sync.log"
    end

    def sync_data
      @logger.info "Starting optimized apdemande data synchronization"

      # Get total count first
      total_count = @db_service.execute_query("SELECT COUNT(*) FROM stg_apdemande").first["count"].to_i
      @logger.info "Processing #{total_count} records in batches of #{BATCH_SIZE}"

      if total_count == 0
        @logger.info "No records to process"
        return
      end

      # Process in batches
      offset = 0
      batch_number = 1

      while offset < total_count
        @logger.info "Processing batch #{batch_number} (#{offset + 1}-#{[offset + BATCH_SIZE,
                                                                         total_count].min} of #{total_count})"

        process_batch(offset)

        offset += BATCH_SIZE
        batch_number += 1

        # Progress reporting
        progress = ((offset.to_f / total_count) * 100).round(2)
        @logger.info "Progress: #{progress}% - Stats: Created: #{@stats[:created]}, Updated: #{@stats[:updated]}, Errors: #{@stats[:errors]}, Skipped: #{@stats[:skipped]}"

        # Memory monitoring
        memory_mb = `ps -o rss= -p #{Process.pid}`.to_i / 1024
        @logger.info "Current memory usage: #{memory_mb}MB"
      end

      @logger.info "Apdemande sync completed. Final stats: Created: #{@stats[:created]}, Updated: #{@stats[:updated]}, Errors: #{@stats[:errors]}, Skipped: #{@stats[:skipped]}"
    end

    private

    def process_batch(offset)
      # Fetch only one batch at a time
      distant_records = @db_service.execute_query(
        "SELECT * FROM stg_apdemande ORDER BY id_demande LIMIT #{BATCH_SIZE} OFFSET #{offset}"
      )

      return if distant_records.ntuples == 0

      begin
        # Preload establishments to avoid N+1 queries
        sirets = distant_records.map { |r| r["siret"] }.compact.uniq
        establishments_by_siret = Establishment.where(siret: sirets).index_by(&:siret)

        # Preload existing records to avoid N+1 queries
        id_demandes = distant_records.map { |r| r["id_demande"] }.compact
        existing_records = OsfApdemande.where(id_demande: id_demandes).index_by(&:id_demande)

        # Prepare bulk operations
        records_to_create = []
        records_to_update = []

        distant_records.each do |record|
          establishment = establishments_by_siret[record["siret"]]
          unless establishment
            increment_stat(:skipped)
            @logger.warn "No establishment found for siret: #{record['siret']}"
            next
          end

          attributes = build_apdemande_attributes(record)
          existing_record = existing_records[record["id_demande"]]

          if existing_record
            records_to_update << { record: existing_record, attributes: attributes }
          else
            records_to_create << attributes
          end
        end

        # Perform bulk operations in a transaction
        ActiveRecord::Base.transaction do
          # Bulk insert new records
          if records_to_create.any?
            OsfApdemande.insert_all(records_to_create)
            increment_stat(:created, records_to_create.size)
            @logger.debug "Bulk created #{records_to_create.size} apdemande records"
          end

          # Update existing records (could be further optimized with update_all for identical updates)
          records_to_update.each do |item|
            item[:record].update!(item[:attributes])
            increment_stat(:updated)
          end

          @logger.debug "Updated #{records_to_update.size} apdemande records" if records_to_update.any?
        end
      rescue StandardError => e
        @logger.error "Error processing batch at offset #{offset}: #{e.message}"
        @logger.error e.backtrace.join("\n")
        increment_stat(:errors)
      end
    end

    def increment_stat(key, count = 1)
      @stats[key] += count
    end

    def build_apdemande_attributes(distant_record)
      {
        id_demande: distant_record["id_demande"],
        siret: distant_record["siret"],
        effectif_entreprise: safe_to_integer(distant_record["effectif_entreprise"]),
        effectif: safe_to_integer(distant_record["effectif"]),
        date_statut: parse_date(distant_record["date_statut"]),
        periode_debut: parse_date(distant_record["periode_debut"]),
        periode_fin: parse_date(distant_record["periode_fin"]),
        hta: safe_to_float(distant_record["hta"]),
        mta: safe_to_float(distant_record["mta"]),
        effectif_autorise: safe_to_integer(distant_record["effectif_autorise"]),
        motif_recours_se: safe_to_integer(distant_record["motif_recours_se"]),
        heures_consommees: safe_to_float(distant_record["heures_consommees"]),
        montant_consomme: safe_to_float(distant_record["montant_consomme"]),
        effectif_consomme: safe_to_integer(distant_record["effectif_consomme"]),
        perimetre: safe_to_integer(distant_record["perimetre"])
      }
    end
  end
end
