# lib/tasks/osf_urssaf_sync_all.rake
# Synchronize all URSSAF-related data in a single command
# usage: rake osf:sync_urssaf[24]

namespace :osf do
  desc "Sync all URSSAF data (cotisation, debit, delai, procol, effectifs) then update denormalized company columns"
  task :sync_urssaf, [:months_back] => :environment do |_task, args|
    months_back = args[:months_back]&.to_i
    if months_back
      puts "Starting URSSAF synchronization for the last #{months_back} months..."
    else
      puts "Starting complete URSSAF synchronization..."
    end

    start_time = Time.current

    Rake::Task["osf:sync_cotisation"].invoke(months_back)
    Rake::Task["osf:sync_debit"].invoke(months_back)
    Rake::Task["osf:sync_delai"].invoke(months_back)
    Rake::Task["osf:sync_procol"].invoke
    Rake::Task["osf:sync_effectif"].invoke(months_back)
    Rake::Task["osf:sync_effectif_ent"].invoke(months_back)
    duration = (Time.current - start_time).round(2)

    puts "\n#{'=' * 50}"
    puts "URSSAF synchronization finished in #{duration} seconds"
    puts "=" * 50
  end
end
