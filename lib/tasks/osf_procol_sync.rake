# lib/tasks/osf_procol_sync.rake
# Synchronize procol data using PostgreSQL cursors for optimal performance
# usage: rake osf:sync_procol[24]

namespace :osf do
  desc "Sync OSF procol data using PostgreSQL cursors (high performance)"
  task :sync_procol, [:months_back] => :environment do |_task, args|
    months_back = args[:months_back]&.to_i
    if months_back
      puts "Syncing procol data for the last #{months_back} months using PostgreSQL cursor"
    else
      puts "Syncing all procol data using PostgreSQL cursor"
    end
    Osf::ProcolSyncService.new(months_back: months_back).perform
  end
end
