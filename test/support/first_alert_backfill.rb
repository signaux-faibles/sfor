# frozen_string_literal: true

# Keep is_first_alert in sync when tests mutate alert data directly.
if Rails.env.test?
  CompanyList.after_save :sync_first_alert_after_alert_change, if: :saved_change_to_alert?
  CompanyScoreEntry.after_save :sync_first_alert_after_score_entry_change, if: :saved_change_to_alert?

  class CompanyList
    private

    def sync_first_alert_after_alert_change
      CompanyLists::FirstAlertComputer.backfill_siren!(siren)
    end
  end

  class CompanyScoreEntry
    private

    def sync_first_alert_after_score_entry_change
      CompanyLists::FirstAlertComputer.backfill_siren!(siren)
    end
  end
end
