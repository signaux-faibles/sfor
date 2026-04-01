# lib/tasks/companies_tracking_status.rake
# usage: rake companies:update_tracking_status
# One-time backfill. After this, EstablishmentTracking callbacks keep the column current.

namespace :companies do # rubocop:disable Metrics/BlockLength
  desc "Backfill companies.tracking_status from establishment_trackings (highest-priority state per siren)"
  task update_tracking_status: :environment do # rubocop:disable Metrics/BlockLength
    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    # Priority order: in_progress > under_surveillance > completed > NULL
    # CASE WHEN uses the same priority logic as the original CTE.
    ActiveRecord::Base.connection.execute(<<~SQL.squish)
      UPDATE companies c
      SET tracking_status = latest.status
      FROM (
        SELECT e.siren,
          CASE
            WHEN bool_or(et.state = 'in_progress')         THEN 'Accompagnement en cours'
            WHEN bool_or(et.state = 'under_surveillance')  THEN 'Accompagnement sous surveillance'
            WHEN bool_or(et.state = 'completed')           THEN 'Accompagnement terminé'
          END AS status
        FROM establishment_trackings et
        INNER JOIN establishments e ON e.siret = et.establishment_siret
        WHERE et.discarded_at IS NULL
        GROUP BY e.siren
      ) latest
      WHERE c.siren = latest.siren
    SQL

    # Clear companies that have no active trackings
    ActiveRecord::Base.connection.execute(<<~SQL.squish)
      UPDATE companies
      SET tracking_status = NULL
      WHERE siren NOT IN (
        SELECT DISTINCT e.siren
        FROM establishment_trackings et
        INNER JOIN establishments e ON e.siret = et.establishment_siret
        WHERE et.discarded_at IS NULL
      )
      AND tracking_status IS NOT NULL
    SQL

    elapsed = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start).round(2)
    count = Company.where.not(tracking_status: nil).count
    puts "Done — #{count} companies with a tracking_status in #{elapsed}s"
  end
end
