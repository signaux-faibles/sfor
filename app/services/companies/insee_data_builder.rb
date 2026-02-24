module Companies
  class InseeDataBuilder
    def initialize(company)
      @company = company
    end

    def build
      return { insee_data: nil, date_fermeture_formatted: nil } if @company.siren.blank?

      service = Api::InseeApiService.new
      insee_data = service.fetch_unite_legale_by_siren(@company.siren)
      date_fermeture_formatted = format_date_fermeture(insee_data)
      merge_siege_address!(insee_data, service)

      { insee_data: insee_data, date_fermeture_formatted: date_fermeture_formatted }
    rescue StandardError
      { insee_data: nil, date_fermeture_formatted: nil }
    end

    private

    def format_date_fermeture(insee_data)
      date_fermeture = insee_data&.dig("data", "date_fermeture")
      return if date_fermeture.blank?

      Time.zone.at(date_fermeture).to_date.strftime("%d/%m/%Y")
    end

    def merge_siege_address!(insee_data, service)
      siege_data = service.fetch_unite_legale_by_siren_siege(@company.siren)
      return if siege_data&.dig("data", "adresse").blank?

      insee_data["data"] ||= {}
      insee_data["data"]["adresse"] = siege_data["data"]["adresse"]
    end
  end
end
