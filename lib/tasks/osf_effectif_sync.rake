# lib/tasks/osf_effectif_sync.rake
# Synchronize effectif data using PostgreSQL cursors for optimal performance
# usage: rake osf:sync_effectif_cursor[24]

namespace :osf do
  desc "Sync OSF effectif data using PostgreSQL cursors (high performance)"
  task :sync_effectif, [:months_back] => :environment do |_task, args|
    months_back = args[:months_back]&.to_i
    if months_back
      puts "Syncing effectif data for the last #{months_back} months using PostgreSQL cursor"
    else
      puts "Syncing all effectif data using PostgreSQL cursor"
    end
    Osf::EffectifSyncServiceWithCursor.new(months_back: months_back).perform
  end
end
