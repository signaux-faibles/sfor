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

      return false if siren_cleaned.length != 9

      @siren = siren_cleaned # Use cleaned version
      true
    end
  end
end
