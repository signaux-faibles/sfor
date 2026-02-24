module Companies
  # This service returns an array of periods and an array of formatted periods.
  # The periods are in the format YYYY-MM-DD.
  # The formatted periods are in the format "Month Year".

  class PeriodsBuilder
    def self.build(start_date)
      end_date = Date.current.end_of_month
      current_date = start_date
      periodes = []

      while current_date <= end_date
        periodes << current_date.beginning_of_month.iso8601
        current_date = current_date.next_month
      end

      formatted = periodes.map do |date_str|
        d = Date.parse(date_str)
        I18n.l(d, format: "%B %Y", locale: :fr).capitalize
      end

      [periodes, formatted]
    end
  end
end
