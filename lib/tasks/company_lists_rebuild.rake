# lib/tasks/company_lists_rebuild.rake
# Rebuilds the company_lists join table from company_score_entries.
# Run after importing a new JSON score file.
# usage:
#   rake lists:rebuild_company_lists               # rebuild all lists
#   rake lists:rebuild_company_lists[Janvier 2026] # rebuild one list

namespace :lists do
  desc "Rebuild company_lists (siren, list_id, score, alert) from the latest company_score_entries per list"
  task :rebuild_company_lists, [:list_name] => :environment do |_task, args|
    lists = args[:list_name].present? ? [List.find_by!(label: args[:list_name])] : List.all

    lists.each do |list|
      puts "Rebuilding company_lists for '#{list.label}'..."
      start = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      ActiveRecord::Base.transaction do
        CompanyList.where(list_id: list.id).delete_all

        ActiveRecord::Base.connection.execute(
          ActiveRecord::Base.sanitize_sql_array([<<~SQL.squish, list.id, list.label])
            INSERT INTO company_lists (siren, list_id, score, alert, created_at, updated_at)
            SELECT DISTINCT ON (siren) siren, ?, score, alert, NOW(), NOW()
            FROM company_score_entries
            WHERE list_name = ?
            ORDER BY siren, created_at DESC
          SQL
        )
      end

      elapsed = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start).round(2)
      puts "  Done — #{CompanyList.where(list_id: list.id).count} entries in #{elapsed}s"
    end
  end
end
