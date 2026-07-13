# lib/tasks/company_lists_rebuild.rake
# Rebuilds the company_lists join table from company_score_entries.
# Run after importing a new JSON score file.
# usage:
#   rake lists:rebuild_company_lists               # rebuild all lists
#   rake lists:rebuild_company_lists[Janvier 2026] # rebuild one list

namespace :lists do # rubocop:disable Metrics/BlockLength
  desc "Rebuild company_lists from the latest company_score_entries per list (score, alert, score breakdown, department, is_first_alert)"
  task :rebuild_company_lists, [:list_name] => :environment do |_task, args| # rubocop:disable Metrics/BlockLength
    lists = args[:list_name].present? ? [List.find_by!(label: args[:list_name])] : List.all

    lists.each do |list| # rubocop:disable Metrics/BlockLength
      puts "Rebuilding company_lists for '#{list.label}'..."
      start = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      ActiveRecord::Base.transaction do
        CompanyList.where(list_id: list.id).delete_all

        # JSONB breakdown extracted once here so the Excel export never needs to read
        # macro_expl from company_score_entries at query time.
        score_columns = Companies::MacroExplGroups.score_columns.join(", ")
        score_selects = Companies::MacroExplGroups::ALL.map do |entry|
          Companies::MacroExplGroups.macro_expl_value_sql(entry)
        end.join(", ")

        ActiveRecord::Base.connection.execute(
          ActiveRecord::Base.sanitize_sql_array([<<~SQL.squish, list.id, list.label])
            INSERT INTO company_lists (
              siren, list_id, score, alert,
              #{score_columns},
              department, created_at, updated_at
            )
            SELECT DISTINCT ON (cse.siren)
              cse.siren, ?, cse.score, cse.alert,
              #{score_selects},
              COALESCE(c.department, ''),
              NOW(), NOW()
            FROM company_score_entries cse
            LEFT JOIN companies c ON c.siren = cse.siren
            WHERE cse.list_name = ?
            ORDER BY cse.siren, cse.created_at DESC
          SQL
        )
      end

      elapsed = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start).round(2)
      puts "  Done — #{CompanyList.where(list_id: list.id).count} entries in #{elapsed}s"

      CompanyLists::FirstAlertComputer.backfill_list!(list)
      first_alert_count = CompanyList.where(list_id: list.id, is_first_alert: true).count
      puts "  is_first_alert backfill — #{first_alert_count} première(s) alerte(s)"
    end
  end
end
