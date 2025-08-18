# lib/tasks/osf_apdemande_sync.rake
# Synchronize OSF apdemande data from OSF database
# usage: rake osf:sync_apdemande

namespace :osf do
  desc "Sync OSF apdemande data from OSF database to local Rails tables"
  task sync_apdemande: :environment do
    OsfApdemandeSyncService.new.perform
  end
end
