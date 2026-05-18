# lib/tasks/companies_procol_status.rake
# Recomputes the denormalized current_procol_status on the companies table.
# Run after every osf:sync_procol to keep the value fresh.
# usage: rake companies:update_procol_status

# Latest active libelle_procol per siren (matches procol_at_date action_procol filter).
ACTIVE_PROCOL_STATUSES_SQL = <<~SQL.squish
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
SQL

namespace :companies do
  desc "Update companies.current_procol_status from the latest osf_procols rows per siren"
  task update_procol_status: :environment do
    puts "Updating companies.current_procol_status..."

    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    conn = ActiveRecord::Base.connection

    # Step 1: set active libelle_procol (uses index_osf_procols_on_siren_action_procol_date_effet).
    result = conn.execute(<<~SQL.squish)
      UPDATE companies c
      SET current_procol_status = ps.libelle_procol
      FROM (#{ACTIVE_PROCOL_STATUSES_SQL}) ps
      WHERE c.siren = ps.siren
    SQL

    # Step 2: clear companies that left procol (still have a stale non-NULL status).
    cleared = conn.execute(<<~SQL.squish)
      UPDATE companies c
      SET current_procol_status = NULL
      WHERE c.current_procol_status IS NOT NULL
        AND NOT EXISTS (
          SELECT 1 FROM (#{ACTIVE_PROCOL_STATUSES_SQL}) ps WHERE ps.siren = c.siren
        )
    SQL

    elapsed = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start).round(2)
    puts "Done — #{result.cmd_tuples} set as in-procol, #{cleared.cmd_tuples} cleared in #{elapsed}s"
  end
end
