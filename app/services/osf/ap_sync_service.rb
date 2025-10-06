# app/services/osf/ap_sync_service.rb
# Service to synchronize ap data from clean_ap materialized view

module Osf
  class ApSyncService < BaseOsfSyncService
    BATCH_SIZE = 1000 # Process in chunks of 1000 records

    def initialize(months_back: nil)
      super()
      @months_back = months_back
      @schema = ENV.fetch("OSF_DATABASE_SCHEMA", "public")
      @source_relation = "#{@schema}.clean_ap"
    end

    protected

    def log_file_name
      "osf_ap_sync.log"
    end

    def sync_data # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      @logger.info "Starting optimized ap data synchronization from clean_ap"

      @logger.info "Clearing existing osf_aps table"
      OsfAp.delete_all

      # Build date filter if months_back is specified
      date_filter = ""
      if @months_back
        cutoff_date = @months_back.months.ago.beginning_of_month
        date_filter = "WHERE periode >= '#{cutoff_date.strftime('%Y-%m-%d')}'"
        @logger.info "Filtering data from #{cutoff_date.strftime('%Y-%m-%d')} onwards (#{@months_back} months back)"
      end

      # Get total count first for batch processing
      count_query = "SELECT COUNT(*) FROM #{@source_relation} #{date_filter}"
      total_count = @db_service.execute_query(count_query).first["count"].to_i
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
        @logger.info "Progress: #{progress}% - Stats: Created: #{@stats[:created]}, Errors: #{@stats[:errors]}, Skipped: #{@stats[:skipped]}" # rubocop:disable Layout/LineLength

        # Memory monitoring
        memory_mb = `ps -o rss= -p #{Process.pid}`.to_i / 1024
        @logger.info "Current memory usage: #{memory_mb}MB"
      end

      @logger.info "Ap sync completed. Final stats: Created: #{@stats[:created]}, Errors: #{@stats[:errors]}, Skipped: #{@stats[:skipped]}" # rubocop:disable Layout/LineLength
    end

    private

    def process_batch(offset) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      # Build date filter if months_back is specified
      date_filter = ""
      if @months_back
        cutoff_date = @months_back.months.ago.beginning_of_month
        date_filter = "WHERE periode >= '#{cutoff_date.strftime('%Y-%m-%d')}'"
      end

      # Fetch only one batch at a time
      distant_records = @db_service.execute_query(
        "SELECT * FROM #{@source_relation} #{date_filter} ORDER BY siret, periode LIMIT #{BATCH_SIZE} OFFSET #{offset}"
      )

      return if distant_records.ntuples.zero?

      begin
        # Preload establishments to avoid N+1 queries
        sirets = distant_records.pluck("siret").compact.uniq
        establishments_by_siret = Establishment.where(siret: sirets).index_by(&:siret)

        # Prepare bulk operations
        records_to_create = []

        distant_records.each do |record|
          establishment = establishments_by_siret[record["siret"]]
          unless establishment
            increment_stat(:skipped)
            @logger.warn "No establishment found for siret: #{record['siret']}"
            next
          end

          attributes = build_ap_attributes(record)
          records_to_create << attributes
        end

        # Perform bulk operations in a transaction
        ActiveRecord::Base.transaction do
          # Bulk insert new records
          if records_to_create.any?
            OsfAp.insert_all(records_to_create)
            increment_stat(:created, records_to_create.size)
            @logger.debug "Bulk created #{records_to_create.size} ap records"
          end
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

    def build_ap_attributes(distant_record)
      {
        siret: distant_record["siret"],
        siren: distant_record["siren"],
        periode: parse_date(distant_record["periode"]),
        etp_autorise: safe_to_float(distant_record["etp_autorise"]),
        etp_consomme: safe_to_float(distant_record["etp_consomme"]),
        motif_recours: distant_record["motif_recours"]
      }
    end
  end
end
