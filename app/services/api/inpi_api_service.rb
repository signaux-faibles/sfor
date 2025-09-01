module Api
  class InpiApiService < Api::BaseApiService
    def initialize(siren:)
      super()
      @siren = siren
    end

    def fetch_extrait_rne
      return nil unless valid_siren?

      endpoint = "/v3/inpi/rne/unites_legales/#{@siren}/extrait_rne"
      make_api_request(endpoint)
    end

    private

    def valid_siren?
      return false if @siren.blank?

      # SIREN must be exactly 9 digits
      siren_cleaned = @siren.to_s.gsub(/\D/, "") # Remove non-digits

      if siren_cleaned.length != 9
        Rails.logger.error "SIREN invalide pour INPI: '#{@siren}' (longueur: #{siren_cleaned.length}, attendu: 9)"
        return false
      end

      @siren = siren_cleaned # Use cleaned version
      Rails.logger.debug { "SIREN valide pour INPI: #{@siren}" }
      true
    end
  end
end
