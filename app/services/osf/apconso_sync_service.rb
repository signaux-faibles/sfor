# app/services/osf/apconso_sync_service.rb
# Service to synchronize apconso data from osf database

module Osf
  class ApconsoSyncService < BaseOsfSyncService # rubocop:disable Metrics/ClassLength
    BATCH_SIZE = 1000 # Process in chunks of 1000 records

    protected

    def log_file_name
      "osf_apconso_sync.log"
    end

    def sync_data # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      @logger.info "Starting optimized apconso data synchronization"

      # Get total count first
      total_count = @db_service.execute_query("SELECT COUNT(*) FROM stg_apconso").first["count"].to_i
      @logger.info "Processing #{total_count} records in batches of #{BATCH_SIZE}"

      if total_count.zero?
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
        @logger.info "Progress: #{progress}% - Stats: Created: #{@stats[:created]}, Updated: #{@stats[:updated]}, Errors: #{@stats[:errors]}, Skipped: #{@stats[:skipped]}" # rubocop:disable Layout/LineLength

        # Memory monitoring
        memory_mb = `ps -o rss= -p #{Process.pid}`.to_i / 1024
        @logger.info "Current memory usage: #{memory_mb}MB"
      end

      @logger.info "Apconso sync completed. Final stats: Created: #{@stats[:created]}, Updated: #{@stats[:updated]}, Errors: #{@stats[:errors]}, Skipped: #{@stats[:skipped]}" # rubocop:disable Layout/LineLength
    end

    private

    def process_batch(offset) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
      # Fetch only one batch at a time
      distant_records = @db_service.execute_query(
        "SELECT * FROM stg_apconso ORDER BY siret, id_demande, periode LIMIT #{BATCH_SIZE} OFFSET #{offset}"
      )

      return if distant_records.ntuples.zero?

      begin
        # Preload establishments to avoid N+1 queries
        sirets = distant_records.pluck("siret").compact.uniq
        establishments_by_siret = Establishment.where(siret: sirets).index_by(&:siret)

        # Preload existing records to avoid N+1 queries
        # For apconso, we need to check composite key: siret + id_demande + periode
        existing_records = {}
        distant_records.each do |record|
          periode = parse_date(record["periode"])
          key = "#{record['siret']}_#{record['id_demande']}_#{periode}"
          existing_records[key] = nil

          # Batch lookup for existing records
          periode = parse_date(record["periode"])
          key = "#{record['siret']}_#{record['id_demande']}_#{periode}"
          existing_record = OsfApconso.find_by(
            siret: record["siret"],
            id_demande: record["id_demande"],
            periode: periode
          )
          existing_records[key] = existing_record if existing_record
        end

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

          attributes = build_apconso_attributes(record)
          periode = parse_date(record["periode"])
          key = "#{record['siret']}_#{record['id_demande']}_#{periode}"
          existing_record = existing_records[key]

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
            OsfApconso.insert_all(records_to_create)
            increment_stat(:created, records_to_create.size)
            @logger.debug "Bulk created #{records_to_create.size} apconso records"
          end

          # Update existing records
          records_to_update.each do |item|
            item[:record].update!(item[:attributes])
            increment_stat(:updated)
          end

          @logger.debug "Updated #{records_to_update.size} apconso records" if records_to_update.any?
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

    def build_apconso_attributes(distant_record)
      {
        siret: distant_record["siret"],
        id_demande: distant_record["id_demande"],
        heures_consommees: safe_to_float(distant_record["heures_consommees"]),
        montant: safe_to_float(distant_record["montant"]),
        effectif: safe_to_integer(distant_record["effectif"]),
        periode: parse_date(distant_record["periode"])
      }
    end
  end
end
