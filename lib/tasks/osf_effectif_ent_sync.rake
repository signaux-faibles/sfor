# lib/tasks/osf_effectif_ent_sync.rake
# Synchronize effectif_ent data using PostgreSQL cursors for optimal performance
# usage: rake osf:sync_effectif_ent[24]

namespace :osf do
  desc "Sync OSF effectif_ent data using PostgreSQL cursors (high performance)"
  task :sync_effectif_ent, [:months_back] => :environment do |_task, args|
    months_back = args[:months_back]&.to_i
    if months_back
      puts "Syncing effectif_ent data for the last #{months_back} months using PostgreSQL cursor"
    else
      puts "Syncing all effectif_ent data using PostgreSQL cursor"
    end
    Osf::EffectifEntSyncService.new(months_back: months_back).perform
  end
end
