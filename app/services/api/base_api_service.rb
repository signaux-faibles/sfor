require "net/http"
require "uri"
require "json"
require "jwt"

module Api
  class BaseApiService
    HOST = Rails.env.production? ? "entreprise.api.gouv.fr" : "staging.entreprise.api.gouv.fr"
    BASE_URL = "https://#{HOST}".freeze

    def initialize
      @token = ENV.fetch("API_ENTREPRISES_TOKEN", nil)
      @recipient = ENV.fetch("API_ENTREPRISES_RECIPIENT", nil)
    end

    protected

    def valid_configuration?
      @token && @recipient
    end

    def valid_token? # rubocop:disable Metrics/MethodLength
      return false unless @token

      begin
        decoded_token = JWT.decode(@token, nil, false)
        expiration = Time.at(decoded_token[0]["exp"])
        if expiration < Time.now
          Rails.logger.error "Token JWT expiré"
          return false
        end
        true
      rescue JWT::DecodeError => e
        Rails.logger.error "Erreur de décodage du token JWT: #{e.message}"
        false
      end
    end

    def make_api_request(endpoint, params = {}) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      return nil unless valid_configuration? && valid_token?

      # Construction de l'URL avec les paramètres
      default_params = {
        recipient: @recipient,
        context: "Signaux Faibles",
        object: "Consultation de données"
      }
      uri = URI("#{BASE_URL}#{endpoint}")
      uri.query = URI.encode_www_form(default_params.merge(params))

      # Configuration de la requête HTTP
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER

      request = Net::HTTP::Get.new(uri)
      request["Authorization"] = "Bearer #{@token}"
      request["User-Agent"] = "SignauxFaibles/#{Rails.env} (Ruby/#{RUBY_VERSION}; Rails/#{Rails.version})"
      request["Accept"] = "*/*"
      request["Cache-Control"] = "no-cache"
      request["Host"] = HOST

      # Exécution de la requête
      response = http.request(request)
      Rails.logger.debug response.body

      if response.is_a?(Net::HTTPSuccess)
        JSON.parse(response.body)
      else
        Rails.logger.error "Erreur API: #{response.code} - #{response.body}"
        nil
      end
    rescue StandardError => e
      Rails.logger.error "Erreur lors de la requête API: #{e.message}"
      nil
    end
  end
end
