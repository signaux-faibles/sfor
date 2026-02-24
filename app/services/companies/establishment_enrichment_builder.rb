module Companies
  class EstablishmentEnrichmentBuilder
    def initialize(establishments)
      @establishments = establishments
      @data_freshness = Import.find_by(name: "osf_effectif")&.data_freshness
    end

    def build
      @establishments.map do |establishment|
        safe_enriched_establishment(establishment)
      end
    end

    private

    def safe_enriched_establishment(establishment)
      build_enriched_establishment(establishment)
    rescue StandardError
      build_fallback_enriched_establishment(establishment)
    end

    def build_enriched_establishment(establishment)
      service = Api::InseeApiService.new(siret: establishment.siret, siren: nil)
      api_data = service.fetch_establishment_by_siret(establishment.siret)
      insee_data = api_data&.dig("data")
      date_fermeture_formatted = formatted_date_from_timestamp(insee_data&.dig("date_fermeture"))

      {
        rails_data: establishment,
        insee_data: insee_data,
        has_api_data: insee_data.present?,
        last_effectif: OsfEffectif.last_effectif_for_siret_in_freshness_month(establishment.siret, @data_freshness),
        active_dette_urssaf: OsfDelai.active_dette_urssaf?(establishment.siret),
        etat_administratif: insee_data&.dig("etat_administratif"),
        date_fermeture_formatted: date_fermeture_formatted
      }
    end

    def build_fallback_enriched_establishment(establishment)
      {
        rails_data: establishment,
        insee_data: nil,
        has_api_data: false,
        last_effectif: OsfEffectif.last_effectif_for_siret_in_freshness_month(establishment.siret, @data_freshness),
        active_dette_urssaf: OsfDelai.active_dette_urssaf?(establishment.siret),
        etat_administratif: nil,
        date_fermeture_formatted: nil
      }
    end

    def formatted_date_from_timestamp(timestamp)
      return if timestamp.blank?

      Time.zone.at(timestamp).strftime("%d/%m/%Y")
    end
  end
end
