# app/services/osf/effectif_sync_service.rb
# Service to synchronize effectif data from stg_effectif materialized view

module Osf
  class EffectifSyncService < BaseOsfSyncService # rubocop:disable Metrics/ClassLength
    BATCH_SIZE = 1000

    def initialize(months_back: nil)
      super()
      @months_back = months_back
      @schema = ENV.fetch("OSF_DATABASE_SCHEMA", "public")
      @source_relation = "#{@schema}.stg_effectif"
    end

    protected

    def log_file_name
      "osf_effectif_sync.log"
    end

    def sync_data # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      @logger.info "Starting effectif data synchronization from #{@source_relation}"

      # Clear existing data before importing
      @logger.info "Clearing existing osf_effectifs table"
      OsfEffectif.delete_all

      # Build base date filter if months_back is specified
      base_date_filter = ""
      if @months_back
        cutoff_date = @months_back.months.ago.beginning_of_month
        base_date_filter = "periode >= '#{cutoff_date.strftime('%Y-%m-%d')}'"
        @logger.info "Filtering data from #{cutoff_date.strftime('%Y-%m-%d')} onwards (#{@months_back} months back)"
      end

      # Cursor-based pagination
      last_siret = nil
      last_periode = nil
      batch_number = 1
      total_processed = 0

      loop do
        @logger.info "Processing batch #{batch_number} (cursor: siret=#{last_siret}, periode=#{last_periode})"

        batch_result = process_batch_cursor(last_siret, last_periode, base_date_filter)

        if (batch_result[:processed]).zero?
          if (batch_result[:total_fetched]).positive?
            @logger.warn "Batch returned #{batch_result[:total_fetched]} records but all were skipped. Continuing..."
            # Update cursor even if all records were skipped
            last_siret = batch_result[:last_siret]
            last_periode = batch_result[:last_periode]
            batch_number += 1
            next
          else
            @logger.info "No more records to process"
            break
          end
        end

        last_siret = batch_result[:last_siret]
        last_periode = batch_result[:last_periode]
        total_processed += batch_result[:processed]
        batch_number += 1

        @logger.info "Batch #{batch_number - 1} completed: #{batch_result[:processed]} records processed.
        Total: #{total_processed} -
        Stats: Created: #{@stats[:created]}, Errors: #{@stats[:errors]}, Skipped: #{@stats[:skipped]}"
      end

      @logger.info "Effectif sync completed. Final stats:
      Created: #{@stats[:created]}, Errors: #{@stats[:errors]}, Skipped: #{@stats[:skipped]}"
    end

    private

    def process_batch_cursor(last_siret, last_periode, base_date_filter) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Metrics/PerceivedComplexity,Metrics/CyclomaticComplexity
      # Build cursor condition
      cursor_condition = ""
      if last_siret && last_periode
        cursor_condition = "(siret > '#{last_siret}' OR (siret = '#{last_siret}' AND periode > '#{last_periode}'))"
      end

      # Build complete WHERE clause
      where_clause = ""
      if base_date_filter.present? || cursor_condition.present?
        conditions = [base_date_filter, cursor_condition].compact.compact_blank
        where_clause = "WHERE #{conditions.join(' AND ')}" if conditions.any?
      end

      query = "SELECT * FROM #{@source_relation} #{where_clause} ORDER BY siret, periode LIMIT #{BATCH_SIZE}"
      @logger.debug "Executing query: #{query}"

      distant_records = @db_service.execute_query(query)

      return { processed: 0, total_fetched: 0, last_siret: last_siret,
               last_periode: last_periode } if distant_records.ntuples.zero?

      sirets = distant_records.pluck("siret").compact.uniq
      establishments_by_siret = Establishment.where(siret: sirets).index_by(&:siret)

      records_to_create = []
      processed_count = 0

      distant_records.each do |record|
        establishment = establishments_by_siret[record["siret"]]
        unless establishment
          increment_stat(:skipped)
          @logger.warn "No establishment found for siret: #{record['siret']}"
          next
        end

        records_to_create << build_effectif_attributes(record)
        processed_count += 1
      end

      @logger.debug "Batch stats: #{processed_count} processed,
      #{records_to_create.size} to create,
      #{distant_records.ntuples} total records"

      if records_to_create.any?
        ActiveRecord::Base.transaction do
          OsfEffectif.insert_all(records_to_create)
          increment_stat(:created, records_to_create.size)
          @logger.debug "Bulk created #{records_to_create.size} effectif records"
        end
      end

      # Get the last record for cursor
      last_record = distant_records.to_a.last
      @logger.debug "Cursor update: last_siret=#{last_record['siret']}, last_periode=#{last_record['periode']}"
      {
        processed: processed_count,
        total_fetched: distant_records.ntuples,
        last_siret: last_record["siret"],
        last_periode: last_record["periode"]
      }
    rescue StandardError => e
      @logger.error "Error processing batch: #{e.message}"
      @logger.error e.backtrace.join("\n")
      increment_stat(:errors)
      { processed: 0, total_fetched: 0, last_siret: last_siret, last_periode: last_periode }
    end

    def increment_stat(key, count = 1)
      @stats[key] += count
    end

    def build_effectif_attributes(distant_record)
      {
        siret: distant_record["siret"],
        periode: parse_date(distant_record["periode"]),
        effectif: safe_to_integer(distant_record["effectif"])
      }
    end
  end
end
