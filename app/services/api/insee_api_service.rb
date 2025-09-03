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

      if siren_cleaned.length != 9
        Rails.logger.error "SIREN invalide: '#{@siren}' (longueur: #{siren_cleaned.length}, attendu: 9)"
        return false
      end

      @siren = siren_cleaned # Use cleaned version
      Rails.logger.debug { "SIREN valide: #{@siren}" }
      true
    end

    def valid_siren_param?(siren)
      return false if siren.blank?

      # SIREN must be exactly 9 digits
      siren_cleaned = siren.to_s.gsub(/\D/, "") # Remove non-digits

      if siren_cleaned.length != 9
        Rails.logger.error "SIREN invalide pour INSEE: '#{siren}' (longueur: #{siren_cleaned.length}, attendu: 9)"
        return false
      end

      Rails.logger.debug { "SIREN valide pour INSEE: #{siren_cleaned}" }
      true
    end

    def valid_siret_param?(siret)
      return false if siret.blank?

      # SIRET must be exactly 14 digits
      siret_cleaned = siret.to_s.gsub(/\D/, "") # Remove non-digits

      if siret_cleaned.length != 14
        Rails.logger.error "SIRET invalide pour INSEE: '#{siret}' (longueur: #{siret_cleaned.length}, attendu: 14)"
        return false
      end

      Rails.logger.debug { "SIRET valide pour INSEE: #{siret_cleaned}" }
      true
    end
  end
end
