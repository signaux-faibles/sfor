module Companies
  class AlertHistoryBuilder
    def initialize(company)
      @company = company
    end

    def build
      return { alert_history: [], show_alert_history_button: false } if @company.siren.blank?

      lists = List.order(code: :desc)
      alert_history = build_alert_history(lists)

      {
        alert_history: alert_history,
        show_alert_history_button: show_alert_history_button?(alert_history)
      }
    end

    private

    def build_alert_history(lists)
      lists.map do |list|
        entry = CompanyScoreEntry.find_by(siren: @company.siren, list_name: list.label)
        {
          list_name: list.label,
          alert_level: alert_level_for_entry(entry)
        }
      end
    end

    def alert_level_for_entry(entry)
      case entry&.alert&.downcase
      when "alerte seuil f1"
        "high"
      when "alerte seuil f2"
        "moderate"
      else
        "none"
      end
    end

    def show_alert_history_button?(alert_history)
      return false if alert_history.blank?
      return false unless CompanyScoreEntry.exists?(siren: @company.siren)

      alert_count = alert_history_alert_count(alert_history)
      current_alert = alert_history.first[:alert_level]

      return alert_count > 1 if alert_level_alert?(current_alert)

      alert_count.positive?
    end

    def alert_history_alert_count(alert_history)
      alert_history.count { |item| alert_level_alert?(item[:alert_level]) }
    end

    def alert_level_alert?(alert_level)
      %w[high moderate].include?(alert_level)
    end
  end
end
