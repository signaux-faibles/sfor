# lib/tasks/osf_effectif_sync.rake
# Synchronize effectif data from clean_effectif materialized view
# usage: rake osf:sync_effectif[24]

namespace :osf do
  desc "Sync OSF effectif data from clean_effectif materialized view to local Rails tables"
  task :sync_effectif, [:months_back] => :environment do |_task, args|
    months_back = args[:months_back]&.to_i
    if months_back
      puts "Syncing effectif data for the last #{months_back} months"
    else
      puts "Syncing all effectif data"
    end
    Osf::EffectifSyncService.new(months_back: months_back).perform
  end
end
