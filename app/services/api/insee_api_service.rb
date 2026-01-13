module Api
  class InseeApiService < Api::BaseApiService
    def initialize(siret: nil, siren: nil)
      super()
      @siret = siret
      @siren = siren
    end

    def fetch_establishment
      endpoint = "/v3/insee/sirene/etablissements/#{@siret}"
      make_api_request(endpoint)
    end

    def fetch_unite_legale_by_siren(siren)
      return nil unless valid_siren_param?(siren)

      endpoint = "/v3/insee/sirene/unites_legales/#{siren}"
      make_api_request(endpoint)
    end

    def fetch_unite_legale_by_siren_siege(siren)
      return nil unless valid_siren_param?(siren)

      endpoint = "/v3/insee/sirene/unites_legales/#{siren}/siege_social"
      make_api_request(endpoint)
    end

    def fetch_establishment_by_siret(siret)
      return nil unless valid_siret_param?(siret)

      endpoint = "/v3/insee/sirene/etablissements/#{siret}"
      make_api_request(endpoint)
    end

    private

    def valid_siren?
      return false if @siren.blank?

      # SIREN must be exactly 9 digits
      siren_cleaned = @siren.to_s.gsub(/\D/, "") # Remove non-digits

      return false if siren_cleaned.length != 9

      @siren = siren_cleaned # Use cleaned version
      true
    end

    def valid_siren_param?(siren)
      return false if siren.blank?

      # SIREN must be exactly 9 digits
      siren_cleaned = siren.to_s.gsub(/\D/, "") # Remove non-digits

      return false if siren_cleaned.length != 9

      true
    end

    def valid_siret_param?(siret)
      return false if siret.blank?

      # SIRET must be exactly 14 digits
      siret_cleaned = siret.to_s.gsub(/\D/, "") # Remove non-digits

      return false if siret_cleaned.length != 14

      true
    end
  end
end
