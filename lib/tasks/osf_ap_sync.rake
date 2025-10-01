# lib/tasks/osf_ap_sync.rake
# Synchronize OSF ap data from clean_ap materialized view
# usage: rake osf:sync_ap

namespace :osf do
  desc "Sync OSF ap data from clean_ap materialized view to local Rails tables"
  task :sync_ap, [:months_back] => :environment do |_task, args|
    months_back = args[:months_back]&.to_i
    if months_back
      puts "Syncing ap data for the last #{months_back} months"
    else
      puts "Syncing all ap data"
    end
    Osf::ApSyncService.new(months_back: months_back).perform
  end
end
