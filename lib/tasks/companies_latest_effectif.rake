# lib/tasks/companies_latest_effectif.rake
# Recomputes the denormalized latest_effectif and size_id on the companies table.
# Run after every osf:sync_effectif_ent to keep the values fresh.
# usage: rake companies:update_latest_effectif

namespace :companies do
  desc "Update companies.latest_effectif and size_id from the latest osf_ent_effectifs row per siren"
  task update_latest_effectif: :environment do
    puts "Updating companies.latest_effectif and size_id..."

    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    result = ActiveRecord::Base.connection.execute(<<~SQL.squish)
      UPDATE companies c
      SET latest_effectif = oee.effectif,
          size_id = sizes.id
      FROM osf_ent_effectifs oee
      LEFT JOIN sizes ON sizes.name = CASE
        WHEN oee.effectif < 10 THEN 'TPE'
        WHEN oee.effectif < 250 THEN 'PME'
        WHEN oee.effectif < 5000 THEN 'ETI'
        ELSE 'GE'
      END
      WHERE oee.siren = c.siren
        AND oee.is_latest = true
    SQL

    elapsed = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start).round(2)
    puts "Done — #{result.cmd_tuples} companies updated in #{elapsed}s"
  end
end
