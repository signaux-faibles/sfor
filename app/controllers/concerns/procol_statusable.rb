# frozen_string_literal: true

# Provides methods to calculate and enrich procol (procedure collective) status
module ProcolStatusable
  extend ActiveSupport::Concern

  private

  # Calculate procol status for a single siren
  # @param siren [String] The SIREN to query
  # @return [String] The libelle_procol or "In Bonis" if not found or on error
  def procol_status_for_siren(siren)
    current_date = Date.current
    sql = ActiveRecord::Base.sanitize_sql([
                                            "SELECT libelle_procol FROM procol_at_date(?) AS procol WHERE procol.siren = ?",
                                            current_date, siren
                                          ])
    result = ActiveRecord::Base.connection.execute(sql).first
    result ? result["libelle_procol"] : "In Bonis"
  rescue StandardError
    "In Bonis"
  end

  # Enrich a collection of results with procol status
  # Expects results to be an array of hashes with a "siren" key
  # Adds a "procol_status" key to each result
  # @param results [Array<Hash>] Array of result hashes with "siren" key
  def enrich_results_with_procol_status(results)
    return if results.blank?

    sirens = results.pluck("siren").compact.uniq
    return if sirens.blank?

    current_date = Date.current
    procol_statuses = {}

    sql = ActiveRecord::Base.sanitize_sql([
                                            "SELECT siren, libelle_procol FROM procol_at_date(?) AS procol WHERE procol.siren IN (?)",
                                            current_date, sirens
                                          ])
    procol_results = ActiveRecord::Base.connection.execute(sql)

    procol_results.each do |row|
      procol_statuses[row["siren"]] = row["libelle_procol"]
    end

    results.each do |result|
      result["procol_status"] = procol_statuses[result["siren"]] || "In Bonis"
    end
  rescue StandardError
    # If query fails, set all to "In Bonis"
    results.each do |result|
      result["procol_status"] = "Erreur calcul du statut procédure collective"
    end
  end
end
