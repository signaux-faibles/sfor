module Api
  class BanqueDeFranceApiService < Api::BaseApiService
    def initialize(siren:)
      super()
      @siren = siren
    end

    def fetch_bilans
      return nil unless valid_siren?

      endpoint = "/v3/banque_de_france/unites_legales/#{@siren}/bilans"
      make_api_request(endpoint)
    end

    private

    def valid_siren?
      return false if @siren.blank?

      # SIREN must be exactly 9 digits
      siren_cleaned = @siren.to_s.gsub(/\D/, "") # Remove non-digits

      if siren_cleaned.length != 9
        Rails.logger.error "SIREN invalide pour BDF: '#{@siren}' (longueur: #{siren_cleaned.length}, attendu: 9)"
        return false
      end

      @siren = siren_cleaned # Use cleaned version
      Rails.logger.debug { "SIREN valide pour BDF: #{@siren}" }
      true
    end
  end
end
