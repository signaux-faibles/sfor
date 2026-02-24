module Establishments
  class InseeDataBuilder
    def initialize(establishment)
      @establishment = establishment
    end

    def build
      return empty_payload if @establishment.siret.blank?

      service = Api::InseeApiService.new
      insee_data = service.fetch_establishment_by_siret(@establishment.siret)
      siren = insee_data&.dig("data", "unite_legale", "siren")
      company_insee_data = service.fetch_unite_legale_by_siren(siren) if siren.present?
      date_fermeture_formatted = format_date_fermeture(insee_data)

      {
        insee_data: insee_data,
        company_insee_data: company_insee_data,
        date_fermeture_formatted: date_fermeture_formatted
      }
    rescue StandardError
      empty_payload
    end

    private

    def format_date_fermeture(insee_data)
      date_fermeture = insee_data&.dig("data", "date_fermeture")
      return if date_fermeture.blank?

      Time.zone.at(date_fermeture).to_date.strftime("%d/%m/%Y")
    end

    def empty_payload
      { insee_data: nil, company_insee_data: nil, date_fermeture_formatted: nil }
    end
  end
end
