require "net/http"
require "uri"
require "json"

module Api
  class FinancialRatiosApiService
    BASE_URL = "https://data.economie.gouv.fr/api/v2/catalog/datasets/ratios_inpi_bce/records".freeze

    def initialize(siren:)
      @siren = siren.to_s.gsub(/\D/, "") # Remove non-digits
    end

    def fetch_financial_ratios
      return nil unless valid_siren?

      uri = URI(BASE_URL)
      uri.query = URI.encode_www_form({
        where: "siren='#{@siren}'"
      })

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER

      request = Net::HTTP::Get.new(uri)
      request["Accept"] = "application/json"
      request["User-Agent"] = "SignauxFaibles/#{Rails.env} (Ruby/#{RUBY_VERSION}; Rails/#{Rails.version})"

      response = http.request(request)
      Rails.logger.debug "Financial ratios API response: #{response.code}"

      if response.is_a?(Net::HTTPSuccess)
        JSON.parse(response.body)
      else
        Rails.logger.error "Erreur API ratios financiers: #{response.code} - #{response.body}"
        nil
      end
    rescue StandardError => e
      Rails.logger.error "Erreur lors de la requête API ratios financiers: #{e.message}"
      nil
    end

    private

    def valid_siren?
      return false if @siren.blank?

      if @siren.length != 9
        Rails.logger.error "SIREN invalide pour ratios financiers: '#{@siren}' (longueur: #{@siren.length}, attendu: 9)"
        return false
      end

      Rails.logger.debug { "SIREN valide pour ratios financiers: #{@siren}" }
      true
    end
  end
end

