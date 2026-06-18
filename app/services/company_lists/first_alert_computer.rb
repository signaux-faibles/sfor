# frozen_string_literal: true

# Computes and stores the denormalized is_first_alert flag on company_lists.
# A row is a "1ère alerte" when alert is F1/F2 and the SIREN has no prior F1/F2
# in another list within the 18-month window before the current list date.
module CompanyLists
  class FirstAlertComputer
    class << self
      def backfill_list!(list)
        list_date = list.list_date || Date.current
        cutoff_date = list_date - 18.months

        ActiveRecord::Base.connection.exec_update(
          ActiveRecord::Base.sanitize_sql_array([backfill_list_sql, CompanyList::STANDARD_ALERT_VALUES,
                                                 list.label, cutoff_date, list_date,
                                                 CompanyList::STANDARD_ALERT_VALUES, list.id]),
          "CompanyLists FirstAlertComputer backfill_list",
          []
        )
      end

      def backfill_all!
        List.find_each { |list| backfill_list!(list) }
      end

      def backfill_siren!(siren)
        CompanyList.where(siren: siren).includes(:list).find_each do |company_list|
          flag = first_alert?(list: company_list.list, siren:, alert: company_list.alert)
          company_list.update_column(:is_first_alert, flag) if company_list.is_first_alert != flag
        end
      end

      def first_alert?(list:, siren:, alert:)
        return false unless CompanyList.first_alert_eligible?(alert)

        list_date = list.list_date || Date.current
        cutoff_date = list_date - 18.months

        !CompanyScoreEntry
          .joins(:list)
          .where(siren:)
          .where.not(list_name: list.label)
          .exists?(["lists.list_date > ? AND lists.list_date < ? AND company_score_entries.alert IN (?)",
                    cutoff_date, list_date, CompanyList::STANDARD_ALERT_VALUES])
      end

      private

      def backfill_list_sql
        <<~SQL.squish
          UPDATE company_lists AS cl
          SET is_first_alert = COALESCE((
            cl.alert IN (?)
            AND NOT EXISTS (
              SELECT 1
              FROM company_score_entries cse_prior
              INNER JOIN lists l ON l.label = cse_prior.list_name
              WHERE cse_prior.siren = cl.siren
                AND cse_prior.list_name != ?
                AND l.list_date > ?
                AND l.list_date < ?
                AND cse_prior.alert IN (?)
            )
          ), false),
          updated_at = NOW()
          WHERE cl.list_id = ?
        SQL
      end
    end
  end
end
