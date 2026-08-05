# lib/tasks/osf_sync_and_denormalize.rake
# Chains OSF sync then denormalization.
# usage:
#   rake osf:sync_and_denormalize
#   rake osf:sync_and_denormalize[24]
#   rake "osf:sync_and_denormalize[24,Janvier 2026]"

namespace :osf do
  desc "Sync all OSF data then run all denormalization updates"
  task :sync_and_denormalize, %i[months_back list_name] => :environment do |_task, args|
    puts "Starting OSF sync + denormalization..."
    start_time = Time.current

    puts "\n#{'=' * 50}"
    puts "Step 1/2: OSF sync"
    puts "=" * 50
    Rake::Task["osf:sync_all"].invoke(args[:months_back])
    Rake::Task["osf:sync_all"].reenable

    puts "\n#{'=' * 50}"
    puts "Step 2/2: Denormalization"
    puts "=" * 50
    Rake::Task["denormalize:all"].invoke(args[:list_name])
    Rake::Task["denormalize:all"].reenable

    duration = (Time.current - start_time).round(2)

    puts "\n#{'=' * 50}"
    puts "OSF sync + denormalization finished in #{duration} seconds"
    puts "=" * 50
  end
end
