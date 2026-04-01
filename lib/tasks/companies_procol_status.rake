# lib/tasks/companies_procol_status.rake
# Recomputes the denormalized current_procol_status on the companies table.
# Run after every osf:sync_procol to keep the value fresh.
# usage: rake companies:update_procol_status

namespace :companies do # rubocop:disable Metrics/BlockLength
  desc "Update companies.current_procol_status from the latest osf_procols rows per siren"
  task update_procol_status: :environment do
    puts "Updating companies.current_procol_status..."

    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    conn = ActiveRecord::Base.connection

    # Step 1: clear all — companies no longer in procol must become NULL.
    conn.execute("UPDATE companies SET current_procol_status = NULL")

    # Step 2: set the active libelle_procol for companies currently in procol.
    # Mirrors the procol_last_actions + procol_statuses CTEs in the excel generator:
    #   1. Get the latest osf_procols row per (siren, action_procol) up to today.
    #   2. Exclude terminal actions (fin_procedure, inclusion_autre_procedure).
    #   3. Pick one libelle_procol per siren (ordered by action_procol for determinism).
    result = conn.execute(<<~SQL.squish)
      UPDATE companies c
      SET current_procol_status = ps.libelle_procol
      FROM (
        SELECT DISTINCT ON (siren) siren, libelle_procol
        FROM (
          SELECT DISTINCT ON (siren, action_procol)
            siren, action_procol, libelle_procol
          FROM osf_procols
          WHERE date_effet <= CURRENT_DATE
          ORDER BY siren, action_procol, date_effet DESC
        ) last_actions
        WHERE action_procol NOT IN ('fin_procedure', 'inclusion_autre_procedure')
        ORDER BY siren, action_procol
      ) ps
      WHERE c.siren = ps.siren
    SQL

    elapsed = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start).round(2)
    puts "Done — #{result.cmd_tuples} companies set as in-procol in #{elapsed}s"
  end
end
