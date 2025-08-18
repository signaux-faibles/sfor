# lib/tasks/osf_apconso_sync.rake
# Synchronize OSF apconso data from OSF database
# usage: rake osf:sync_apconso

namespace :osf do
  desc "Sync OSF apconso data from OSF database to local Rails tables"
  task sync_apconso: :environment do
    OsfApconsoSyncService.new.perform
  end
end
