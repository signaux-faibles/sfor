# app/services/osf/sirene_sync_service.rb
# Service to synchronize establishments data from clean_sirene view using PostgreSQL cursors

module Osf
  class SireneSyncService < BaseOsfSyncService # rubocop:disable Metrics/ClassLength
    BATCH_SIZE = 1000

    def initialize
      super
      @schema = ENV.fetch("OSF_DATABASE_SCHEMA", "sfdata")
      @source_relation = "#{@schema}.clean_sirene"
    end

    protected

    def log_file_name
      "sirene_sync.log"
    end

    def sync_data # rubocop:disable Metrics/MethodLength
      @logger.info "Starting establishments synchronization from #{@source_relation} using PostgreSQL cursor"

      base_filter = ""

      ActiveRecord::Base.transaction do
        # Set constraints to deferred so we can delete establishments while trackings reference them
        ActiveRecord::Base.connection.execute("SET CONSTRAINTS ALL DEFERRED")

        @logger.info "Clearing existing establishments table"
        Establishment.delete_all

        # Process and insert new establishments (in same transaction)
        process_with_cursor(base_filter)

        # Commit will check deferred constraints - if all new establishments exist, FK passes
      end

      @logger.info "Sirene sync completed.
      Final stats: Created: #{@stats[:created]},
      Errors: #{@stats[:errors]},
      Skipped: #{@stats[:skipped]}"
    end

    private

    def process_with_cursor(base_filter) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      cursor_name = "sirene_cursor_#{Process.pid}_#{Time.current.to_i}"

      begin
        # Cursor operations are on OSF DB (read-only), separate from Rails transaction
        @db_service.execute_query("BEGIN")
        @logger.debug "Declaring cursor: #{cursor_name}"

        declare_sql =
          "DECLARE #{cursor_name} NO SCROLL CURSOR FOR SELECT * FROM #{@source_relation} #{base_filter} ORDER BY siret"
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
          Stats: Created: #{@stats[:created]}, Errors: #{@stats[:errors]}, Skipped: #{@stats[:skipped]}"
        end

        @db_service.execute_query("CLOSE #{cursor_name}")
        @db_service.execute_query("COMMIT")
        @logger.debug "Closed cursor"
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

    def process_cursor_batch(distant_records) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      records_to_create = []
      processed_count = 0

      distant_records.each do |record|
        siret = record["siret"]
        if siret.blank?
          increment_stat(:skipped)
          @logger.warn "Skipping record with missing siret"
          next
        end

        attributes = build_establishment_attributes(record)

        # Skip records with invalid/missing department after normalization
        if attributes[:departement].blank?
          increment_stat(:skipped)
          @logger.warn "Skipping siret #{siret}: invalid or missing departement"
          next
        end

        records_to_create << attributes
        processed_count += 1
      end

      @logger.debug "Batch stats: #{processed_count} processed,
      #{records_to_create.size} to create,
      #{distant_records.ntuples} total records"

      if records_to_create.any?
        ActiveRecord::Base.transaction do
          Establishment.insert_all(records_to_create)
          increment_stat(:created, records_to_create.size)
          @logger.debug "Bulk created #{records_to_create.size} establishment records"
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

    def build_establishment_attributes(distant_record) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      # Compute departement, handling DOM/COM special case where source gives "97"
      source_departement = distant_record["departement"].to_s.strip.upcase
      computed_departement = source_departement
      if source_departement == "97"
        raw_cp = distant_record["code_postal"].to_s
        cp_digits = raw_cp.gsub(/\D/, "")
        computed_departement = cp_digits.start_with?("97") && cp_digits.length >= 3 ? cp_digits[0, 3] : nil
      end

      # Accept only valid department codes; otherwise set to nil (skip invalid/blank/garbage)
      # Valid: 01-95, 2A, 2B, 971-978
      computed_departement = nil unless computed_departement.to_s.match?(/^(?:0[1-9]|[1-8][0-9]|9[0-5]|2A|2B|97[1-8])$/)

      {
        siren: distant_record["siren"],
        siret: distant_record["siret"],
        siege: distant_record["siege"],
        complement_adresse: distant_record["complement_adresse"],
        numero_voie: distant_record["numero_voie"],
        indrep: distant_record["indrep"],
        type_voie: distant_record["type_voie"],
        voie: distant_record["voie"],
        commune: distant_record["commune"],
        commune_etranger: distant_record["commune_etranger"],
        distribution_speciale: distant_record["distribution_speciale"],
        code_commune: distant_record["code_commune"],
        code_cedex: distant_record["code_cedex"],
        cedex: distant_record["cedex"],
        code_pays_etranger: distant_record["code_pays_etranger"],
        pays_etranger: distant_record["pays_etranger"],
        code_postal: distant_record["code_postal"],
        departement: computed_departement,
        ape: distant_record["ape"],
        code_activite: distant_record["code_activite"],
        nomenclature_activite: distant_record["nomenclature_activite"],
        date_creation: parse_date(distant_record["date_creation"]),
        longitude: safe_to_float(distant_record["longitude"]),
        latitude: safe_to_float(distant_record["latitude"])
      }
    end
  end
end
