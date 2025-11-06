# lib/tasks/osf_debit_sync.rake
# Synchronize debit data using PostgreSQL cursors for optimal performance
# usage: rake osf:sync_debit[24]

namespace :osf do
  desc "Sync OSF debit data using PostgreSQL cursors (high performance)"
  task :sync_debit, [:months_back] => :environment do |_task, args|
    months_back = args[:months_back]&.to_i
    if months_back
      puts "Syncing debit data for the last #{months_back} months using PostgreSQL cursor"
    else
      puts "Syncing all debit data using PostgreSQL cursor"
    end
    Osf::DebitSyncService.new(months_back: months_back).perform
  end
end
