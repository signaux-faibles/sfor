require "net/http"
require "uri"
require "json"
require "jwt"

module Api
  class BaseApiService
    HOST = Rails.env.production? ? "entreprise.api.gouv.fr" : "staging.entreprise.api.gouv.fr"
    BASE_URL = "https://#{HOST}".freeze
    OPEN_TIMEOUT = 10
    READ_TIMEOUT = 15

    def initialize
      @token = ENV.fetch("API_ENTREPRISES_TOKEN", nil)
      @recipient = ENV.fetch("API_ENTREPRISES_RECIPIENT", nil)
    end

    protected

    def valid_configuration?
      @token && @recipient
    end

    def valid_token?
      return false unless @token

      begin
        decoded_token = JWT.decode(@token, nil, false)
        expiration = Time.at(decoded_token[0]["exp"])
        return false if expiration < Time.now

        true
      rescue JWT::DecodeError
        false
      end
    end

    def make_api_request(endpoint, params = {}) # rubocop:disable Metrics/MethodLength
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
      http.open_timeout = OPEN_TIMEOUT
      http.read_timeout = READ_TIMEOUT

      request = Net::HTTP::Get.new(uri)
      request["Authorization"] = "Bearer #{@token}"
      request["User-Agent"] = "SignauxFaibles/#{Rails.env} (Ruby/#{RUBY_VERSION}; Rails/#{Rails.version})"
      request["Accept"] = "*/*"
      request["Cache-Control"] = "no-cache"
      request["Host"] = HOST

      # Exécution de la requête
      response = http.request(request)

      unless response.is_a?(Net::HTTPSuccess)
        message = "[#{self.class.name}] API request failed (#{response.code}) for #{endpoint}"
        Rails.logger.warn(message)
        Sentry.capture_message(message, level: :warning, extra: api_error_context(endpoint, response_code: response.code))
        return nil
      end

      JSON.parse(response.body)
    rescue Timeout::Error => e
      Rails.logger.warn("[#{self.class.name}] API request timed out for #{endpoint}: #{e.message}")
      Sentry.capture_exception(e, extra: api_error_context(endpoint))
      nil
    rescue StandardError => e
      Rails.logger.warn("[#{self.class.name}] API request error for #{endpoint}: #{e.message}")
      Sentry.capture_exception(e, extra: api_error_context(endpoint))
      nil
    end

    def api_error_context(endpoint, **extra)
      { endpoint: endpoint, service: self.class.name }.merge(extra)
    end
  end
end
