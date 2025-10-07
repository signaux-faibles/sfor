# app/services/osf/effectif_sync_service.rb
# Service to synchronize effectif data from stg_effectif materialized view

module Osf
  class EffectifSyncService < BaseOsfSyncService
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
      @logger.info "Starting effectif data synchronization from stg_effectif"

      # Clear existing data before importing
      @logger.info "Clearing existing osf_effectifs table"
      OsfEffectif.delete_all

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

      return @logger.info("No records to process") if total_count.zero?

      offset = 0
      batch_number = 1
      while offset < total_count
        @logger.info "Processing batch #{batch_number} (#{offset + 1}-#{[offset + BATCH_SIZE,
                                                                         total_count].min} of #{total_count})"

        process_batch(offset, date_filter)

        offset += BATCH_SIZE
        batch_number += 1

        progress = ((offset.to_f / total_count) * 100).round(2)
        @logger.info "Progress: #{progress}% - Stats:
        Created: #{@stats[:created]},
        Errors: #{@stats[:errors]},
        Skipped: #{@stats[:skipped]}"
      end

      @logger.info "Effectif sync completed. Final stats:
      Created: #{@stats[:created]},
      Errors: #{@stats[:errors]},
      Skipped: #{@stats[:skipped]}"
    end

    private

    def process_batch(offset, date_filter) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      distant_records = @db_service.execute_query(
        "SELECT * FROM #{@source_relation} #{date_filter} ORDER BY siret, periode LIMIT #{BATCH_SIZE} OFFSET #{offset}"
      )

      return if distant_records.ntuples.zero?

      sirets = distant_records.pluck("siret").compact.uniq
      establishments_by_siret = Establishment.where(siret: sirets).index_by(&:siret)

      records_to_create = []

      distant_records.each do |record|
        establishment = establishments_by_siret[record["siret"]]
        unless establishment
          increment_stat(:skipped)
          @logger.warn "No establishment found for siret: #{record['siret']}"
          next
        end

        records_to_create << build_effectif_attributes(record)
      end

      return if records_to_create.empty?

      ActiveRecord::Base.transaction do
        OsfEffectif.insert_all(records_to_create)
        increment_stat(:created, records_to_create.size)
        @logger.debug "Bulk created #{records_to_create.size} effectif records"
      end
    rescue StandardError => e
      @logger.error "Error processing batch at offset #{offset}: #{e.message}"
      @logger.error e.backtrace.join("\n")
      increment_stat(:errors)
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
