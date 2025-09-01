# lib/tasks/osf_sync_all.rake
# Synchronize all OSF data types from OSF database
# usage: rake osf:sync_all

namespace :osf do
  desc "Sync all OSF data from OSF database to local Rails tables"
  task sync_all: :environment do
    puts "Starting complete OSF data synchronization..."

    start_time = Time.current

    # Run all sync tasks
    Rake::Task["osf:sync_apdemande"].invoke
    Rake::Task["osf:sync_apconso"].invoke

    end_time = Time.current
    duration = (end_time - start_time).round(2)

    puts "\n#{'=' * 50}"
    puts "Complete OSF synchronization finished in #{duration} seconds"
    puts "=" * 50
  end
end
