# lib/tasks/sirene_sync.rake
# Synchronize establishments from SIRENE clean view using PostgreSQL cursors
# usage: rake osf:sync_sirene

namespace :osf do
  desc "Sync establishments from SIRENE clean view (cursor-based)"
  task sync_sirene: :environment do
    puts "Syncing establishments from SIRENE (sfdata.clean_sirene) using cursor"
    Osf::SireneSyncService.new.perform
  end
end
