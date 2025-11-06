# lib/tasks/osf_cotisation_sync.rake
# Synchronize cotisation data using PostgreSQL cursors for optimal performance
# usage: rake osf:sync_cotisation[24]

namespace :osf do
  desc "Sync OSF cotisation data using PostgreSQL cursors (high performance)"
  task :sync_cotisation, [:months_back] => :environment do |_task, args|
    months_back = args[:months_back]&.to_i
    if months_back
      puts "Syncing cotisation data for the last #{months_back} months using PostgreSQL cursor"
    else
      puts "Syncing all cotisation data using PostgreSQL cursor"
    end
    Osf::CotisationSyncService.new(months_back: months_back).perform
  end
end
