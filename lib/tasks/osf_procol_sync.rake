# lib/tasks/osf_procol_sync.rake
# Synchronize procol data using PostgreSQL cursors for optimal performance
# usage: rake osf:sync_procol

namespace :osf do
  desc "Sync OSF procol data using PostgreSQL cursors (high performance)"
  task sync_procol: :environment do
    puts "Syncing all procol data using PostgreSQL cursor"
    Osf::ProcolSyncService.new.perform
  end
end
