# lib/tasks/establishments_latest_effectif.rake
# Recomputes the denormalized latest_effectif on the establishments table.
# Run after every osf:sync_effectif to keep the value fresh.
# usage: rake establishments:update_latest_effectif

namespace :establishments do
  desc "Update establishments.latest_effectif from the latest osf_effectifs row per siret"
  task update_latest_effectif: :environment do
    puts "Updating establishments.latest_effectif..."

    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    result = ActiveRecord::Base.connection.execute(<<~SQL.squish)
      UPDATE establishments e
      SET latest_effectif = oe.effectif
      FROM osf_effectifs oe
      WHERE oe.siret = e.siret
        AND oe.is_latest = true
    SQL

    elapsed = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start).round(2)
    puts "Done — #{result.cmd_tuples} establishments updated in #{elapsed}s"
  end
end
