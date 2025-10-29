# app/services/osf/sirene_ul_sync_service.rb
# Service to synchronize companies data from stg_sirene_ul table using PostgreSQL cursors

module Osf
  class SireneUlSyncService < BaseOsfSyncService # rubocop:disable Metrics/ClassLength
    BATCH_SIZE = 1000

    def initialize
      super
      @schema = ENV.fetch("OSF_DATABASE_SCHEMA", "sfdata")
      @source_relation = "#{@schema}.clean_sirene_ul"
    end

    protected

    def log_file_name
      "sirene_ul_sync.log"
    end

    def sync_data
      @logger.info "Starting companies synchronization from #{@source_relation} using PostgreSQL cursor"

      # Build base filter - no date filter for companies sync
      base_filter = ""

      process_with_cursor(base_filter)

      @logger.info "Sirene UL sync completed.
      Final stats: Created: #{@stats[:created]},
      Updated: #{@stats[:updated]},
      Errors: #{@stats[:errors]},
      Skipped: #{@stats[:skipped]}"
    end

    private

    def process_with_cursor(base_filter) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      cursor_name = "sirene_ul_cursor_#{Process.pid}_#{Time.current.to_i}"

      begin
        @db_service.execute_query("BEGIN")
        @logger.debug "Started transaction and declaring cursor: #{cursor_name}"

        declare_sql =
          "DECLARE #{cursor_name} NO SCROLL CURSOR FOR SELECT * FROM #{@source_relation} #{base_filter} ORDER BY siren"
        @db_service.execute_query(declare_sql)
        @logger.debug "Declared cursor with query: #{declare_sql}"

        batch_number = 1
        total_processed = 0

        loop do
          @logger.info "Processing batch #{batch_number}"

          fetch_sql = "FETCH FORWARD #{BATCH_SIZE} FROM #{cursor_name}"
          distant_records = @db_service.execute_query(fetch_sql)

          @logger.debug "Fetched #{distant_records.ntuples} records from cursor"

          break if distant_records.ntuples.zero?

          batch_result = process_cursor_batch(distant_records)
          total_processed += batch_result[:processed]
          batch_number += 1

          @logger.info "Batch #{batch_number - 1} completed: #{batch_result[:processed]} records processed.
          Total: #{total_processed} -
          Stats: Created: #{@stats[:created]}, Updated: #{@stats[:updated]},
          Errors: #{@stats[:errors]}, Skipped: #{@stats[:skipped]}"
        end

        @db_service.execute_query("CLOSE #{cursor_name}")
        @db_service.execute_query("COMMIT")
        @logger.debug "Closed cursor and committed transaction"
      rescue StandardError => e
        @logger.error "Error in cursor processing: #{e.message}"
        @logger.error e.backtrace.join("\n")

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

    def process_cursor_batch(distant_records) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
      sirens = distant_records.pluck("siren").compact.uniq
      existing_companies = Company.where(siren: sirens).index_by(&:siren)

      records_to_create = []
      records_to_update = []
      processed_count = 0

      distant_records.each do |record|
        siren = record["siren"]
        if siren.blank?
          increment_stat(:skipped)
          @logger.warn "Skipping record with missing siren"
          next
        end

        existing = existing_companies[siren]

        if existing
          attributes = build_company_attributes(record)
          records_to_update << { id: existing.id, **attributes }
        else
          records_to_create << build_company_attributes(record)
        end

        processed_count += 1
      end

      @logger.debug "Batch stats: #{processed_count} processed,
      #{records_to_create.size} to create,
      #{records_to_update.size} to update,
      #{distant_records.ntuples} total records"

      if records_to_create.any? || records_to_update.any?
        ActiveRecord::Base.transaction do
          Company.insert_all(records_to_create) if records_to_create.any?
          increment_stat(:created, records_to_create.size) if records_to_create.any?

          if records_to_update.any?
            records_to_update.each do |attrs|
              Company.where(id: attrs[:id]).update_all(attrs.except(:id))
            end
            increment_stat(:updated, records_to_update.size)
          end

          @logger.debug "Bulk processed #{records_to_create.size} created,
          #{records_to_update.size} updated company records"
        end
      end

      { processed: processed_count }
    rescue StandardError => e
      @logger.error "Error processing cursor batch: #{e.message}"
      @logger.error e.backtrace.join("\n")
      increment_stat(:errors)
      { processed: 0 }
    end

    def increment_stat(key, count = 1)
      @stats[key] += count
    end

    def build_company_attributes(distant_record)
      {
        siren: distant_record["siren"],
        raison_sociale: distant_record["raison_sociale"],
        statut_juridique: distant_record["statut_juridique"],
        creation: parse_date(distant_record["creation"])
      }
    end
  end
end
