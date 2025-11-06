# lib/tasks/osf_delai_sync.rake
# Synchronize delai data using PostgreSQL cursors for optimal performance
# usage: rake osf:sync_delai[24]

namespace :osf do
  desc "Sync OSF delai data using PostgreSQL cursors (high performance)"
  task :sync_delai, [:months_back] => :environment do |_task, args|
    months_back = args[:months_back]&.to_i
    if months_back
      puts "Syncing delai data for the last #{months_back} months using PostgreSQL cursor"
    else
      puts "Syncing all delai data using PostgreSQL cursor"
    end
    Osf::DelaiSyncService.new(months_back: months_back).perform
  end
end
