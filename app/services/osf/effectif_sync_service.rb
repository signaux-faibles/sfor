# app/services/osf/effectif_sync_service.rb
# Service to synchronize effectif data using PostgreSQL cursors for optimal performance

module Osf
  class EffectifSyncService < BaseOsfSyncService
    BATCH_SIZE = 1000

    def initialize(months_back: nil)
      super()
      @months_back = months_back
      @schema = ENV.fetch("OSF_DATABASE_SCHEMA", "public")
      @source_relation = "#{@schema}.clean_effectif"
    end

    protected

    def log_file_name
      "osf_effectif_sync.log"
    end

    def sync_data
      @logger.info "Starting effectif data synchronization from #{@source_relation} using PostgreSQL cursor"

      @logger.info "Clearing existing osf_effectifs table"
      OsfEffectif.delete_all

      # Build base date filter if months_back is specified
      base_date_filter = ""
      if @months_back
        cutoff_date = @months_back.months.ago.beginning_of_month
        base_date_filter = "WHERE periode >= '#{cutoff_date.strftime('%Y-%m-%d')}'"
        @logger.info "Filtering data from #{cutoff_date.strftime('%Y-%m-%d')} onwards (#{@months_back} months back)"
      end

      # Use PostgreSQL cursor for efficient processing
      process_with_cursor(base_date_filter)

      @logger.info "Effectif sync completed.
      Final stats: Created: #{@stats[:created]},
      Errors: #{@stats[:errors]}"
    end

    private

    def process_with_cursor(base_date_filter) # rubocop:disable Metrics/MethodLength
      cursor_name = "effectif_cursor_#{Process.pid}_#{Time.current.to_i}"

      begin
        # Start transaction and declare cursor
        @db_service.execute_query("BEGIN")
        @logger.debug "Started transaction and declaring cursor: #{cursor_name}"

        # Declare cursor with the query
        declare_sql =
          "DECLARE #{cursor_name} NO SCROLL CURSOR FOR SELECT * FROM #{@source_relation} #{base_date_filter} ORDER BY siret, periode"
        @db_service.execute_query(declare_sql)
        @logger.debug "Declared cursor with query: #{declare_sql}"

        batch_number = 1
        total_processed = 0

        loop do
          @logger.info "Processing batch #{batch_number}"

          # Fetch batch from cursor
          fetch_sql = "FETCH FORWARD #{BATCH_SIZE} FROM #{cursor_name}"
          distant_records = @db_service.execute_query(fetch_sql)

          @logger.debug "Fetched #{distant_records.ntuples} records from cursor"

          # Break if no more records
          break if distant_records.ntuples.zero?

          # Process the batch
          batch_result = process_cursor_batch(distant_records)
          total_processed += batch_result[:processed]
          batch_number += 1

          @logger.info "Batch #{batch_number - 1} completed: #{batch_result[:processed]} records processed.
          Total: #{total_processed} -
          Stats: Created: #{@stats[:created]}, Errors: #{@stats[:errors]}"
        end

        # Close cursor and commit
        @db_service.execute_query("CLOSE #{cursor_name}")
        @db_service.execute_query("COMMIT")
        @logger.debug "Closed cursor and committed transaction"
      rescue StandardError => e
        @logger.error "Error in cursor processing: #{e.message}"
        @logger.error e.backtrace.join("\n")

        # Clean up cursor and rollback on error
        begin
          @db_service.execute_query("CLOSE #{cursor_name}") if cursor_name
          @db_service.execute_query("ROLLBACK")
        rescue StandardError => cleanup_error
          @logger.error "Error during cleanup: #{cleanup_error.message}"
        end

        increment_stat(:errors)
        raise
      end
    end

    def process_cursor_batch(distant_records)
      records_to_create = distant_records.map do |record|
        build_effectif_attributes(record)
      end

      @logger.debug "Batch stats: #{records_to_create.size}
      records to create from #{distant_records.ntuples} total records"

      if records_to_create.any?
        ActiveRecord::Base.transaction do
          OsfEffectif.insert_all(records_to_create)
          increment_stat(:created, records_to_create.size)
          @logger.debug "Bulk created #{records_to_create.size} effectif records"
        end
      end

      { processed: records_to_create.size }
    rescue StandardError => e
      @logger.error "Error processing cursor batch: #{e.message}"
      @logger.error e.backtrace.join("\n")
      increment_stat(:errors)
      { processed: 0 }
    end

    def increment_stat(key, count = 1)
      @stats[key] += count
    end

    def build_effectif_attributes(distant_record)
      {
        siret: distant_record["siret"],
        periode: parse_date(distant_record["periode"]),
        effectif: safe_to_integer(distant_record["effectif"]),
        is_latest: safe_to_boolean(distant_record["is_latest"])
      }
    end
  end
end
