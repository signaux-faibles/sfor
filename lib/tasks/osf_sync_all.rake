# lib/tasks/osf_sync_all.rake
# Synchronize all OSF data types from OSF database
# usage: rake osf:sync_all

namespace :osf do
  desc "Sync all OSF data from OSF database to local Rails tables"
  task :sync_all, [:months_back] => :environment do |_task, args|
    months_back = args[:months_back]&.to_i
    if months_back
      puts "Starting complete OSF data synchronization for the last #{months_back} months..."
    else
      puts "Starting complete OSF data synchronization..."
    end

    start_time = Time.current

    # Run the new unified ap sync task
    Rake::Task["osf:sync_ap"].invoke(months_back)

    end_time = Time.current
    duration = (end_time - start_time).round(2)

    puts "\n#{'=' * 50}"
    puts "Complete OSF synchronization finished in #{duration} seconds"
    puts "=" * 50
  end
end
