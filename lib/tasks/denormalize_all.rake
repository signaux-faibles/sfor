# lib/tasks/denormalize_all.rake
# Runs all denormalization rake tasks (companies columns + company_lists rebuild).
# usage:
#   rake denormalize:all
#   rake "denormalize:all[Janvier 2026]"  # optional list name for company_lists rebuild

DENORMALIZE_COMPANIES_TASKS = %w[
  companies:update_social_debt_total
  companies:update_latest_effectif
  companies:update_procol_status
  companies:update_delai_urssaf_until
  companies:update_tracking_status
].freeze

namespace :denormalize do
  desc "Run all denormalization updates (companies columns + company_lists rebuild)"
  task :all, [:list_name] => :environment do |_task, args|
    puts "Starting denormalization..."
    start_time = Time.current

    DENORMALIZE_COMPANIES_TASKS.each do |task_name|
      puts "\n#{'-' * 50}"
      Rake::Task[task_name].invoke
      Rake::Task[task_name].reenable
    end

    puts "\n#{'-' * 50}"
    Rake::Task["lists:rebuild_company_lists"].invoke(args[:list_name])
    Rake::Task["lists:rebuild_company_lists"].reenable

    duration = (Time.current - start_time).round(2)

    puts "\n#{'=' * 50}"
    puts "Denormalization finished in #{duration} seconds"
    puts "=" * 50
  end
end
