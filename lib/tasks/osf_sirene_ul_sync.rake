# lib/tasks/sirene_ul_sync.rake
# Synchronize companies (unités légales) from SIRENE UL staging using PostgreSQL cursors
# usage: rake osf:sync_sirene_ul

namespace :osf do
  desc "Sync companies (UL) from SIRENE UL staging (cursor-based)"
  task sync_sirene_ul: :environment do
    puts "Syncing companies from SIRENE UL (sfdata.stg_sirene_ul) using cursor"
    Osf::SireneUlSyncService.new.perform
  end
end
