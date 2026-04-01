# lib/tasks/companies_social_debt.rake
# Recomputes the denormalized social_debt_total on the companies table.
# Run after every osf:sync_debit to keep the value fresh.
# usage: rake companies:update_social_debt_total

namespace :companies do
  desc "Update companies.social_debt_total from the latest osf_debits rows per siren"
  task update_social_debt_total: :environment do
    puts "Updating companies.social_debt_total..."

    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    result = ActiveRecord::Base.connection.execute(<<~SQL)
      UPDATE companies c
      SET social_debt_total = agg.total
      FROM (
        SELECT e.siren,
          COALESCE(SUM(od.part_ouvriere + od.part_patronale), 0) AS total
        FROM establishments e
        INNER JOIN osf_debits od ON od.siret = e.siret AND od.is_last = true
        GROUP BY e.siren
      ) agg
      WHERE c.siren = agg.siren
    SQL

    elapsed = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start).round(2)
    puts "Done — #{result.cmd_tuples} companies updated in #{elapsed}s"
  end
end
