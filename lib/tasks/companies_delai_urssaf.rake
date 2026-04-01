# lib/tasks/companies_delai_urssaf.rake
# usage: rake companies:update_delai_urssaf_until
# Run after each osf:sync_delai to keep companies.delai_urssaf_until current.

namespace :companies do # rubocop:disable Metrics/BlockLength
  desc "Update companies.delai_urssaf_until with MAX(date_echeance) per siren from osf_delais"
  task update_delai_urssaf_until: :environment do
    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    ActiveRecord::Base.connection.execute(<<~SQL.squish)
      UPDATE companies c
      SET delai_urssaf_until = latest.max_echeance
      FROM (
        SELECT e.siren, MAX(od.date_echeance) AS max_echeance
        FROM osf_delais od
        INNER JOIN establishments e ON e.siret = od.siret
        GROUP BY e.siren
      ) latest
      WHERE c.siren = latest.siren
    SQL

    # Clear out companies that no longer have any delai
    ActiveRecord::Base.connection.execute(<<~SQL.squish)
      UPDATE companies
      SET delai_urssaf_until = NULL
      WHERE siren NOT IN (
        SELECT DISTINCT e.siren
        FROM osf_delais od
        INNER JOIN establishments e ON e.siret = od.siret
      )
      AND delai_urssaf_until IS NOT NULL
    SQL

    elapsed = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start).round(2)
    count = Company.where.not(delai_urssaf_until: nil).count
    puts "Done — #{count} companies with a delai_urssaf_until in #{elapsed}s"
  end
end
