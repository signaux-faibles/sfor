require "net/http"
require "uri"
require "json"

module Api
  class RechercheEntreprisesApiService
    BASE_URL = "https://recherche-entreprises.api.gouv.fr".freeze

    attr_reader :errors

    def initialize(params = {})
      @params = params
      @errors = []
    end

    def search_company
      endpoint = "/search"
      response = make_request(endpoint, @params)

      # Check if response contains an error
      if response.is_a?(Hash) && response["erreur"]
        add_error(response["erreur"])
        nil
      else
        response
      end
    end

    private

    def make_request(endpoint, params = {}) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      params = params.to_h if params.respond_to?(:to_h)
      # Remove blank values
      params = params.reject { |_k, v| v.blank? || (v.is_a?(Array) && v.compact_blank.empty?) }

      uri = URI("#{BASE_URL}#{endpoint}")
      uri.query = URI.encode_www_form(params) if params.any?

      Rails.logger.debug { "URI: #{uri}" }
      Rails.logger.debug { "Params: #{params}" }

      # Configuration de la requête HTTP
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      http.open_timeout = 30
      http.read_timeout = 30

      request = Net::HTTP::Get.new(uri)
      request["User-Agent"] = "SignauxFaibles/#{Rails.env} (Ruby/#{RUBY_VERSION}; Rails/#{Rails.version})"
      request["Accept"] = "application/json"

      # Exécution de la requête
      response = http.request(request)

      Rails.logger.debug { "Response: #{response.body}" }

      handle_response(response)
    rescue StandardError => e
      add_error("Erreur de connexion à l'API Recherche Entreprises: #{e.message}")
      Rails.logger.error "#{self.class.name}: #{e.message}"
      nil
    end

    def handle_response(response) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
      Rails.logger.debug { "Response code: #{response.code}" }
      Rails.logger.debug { "Response body: #{response.body}" }

      # Ensure response body is UTF-8 encoded
      body_utf8 = response.body.force_encoding("UTF-8")
      body_utf8 = body_utf8.encode("UTF-8", invalid: :replace, undef: :replace) unless body_utf8.valid_encoding?

      case response.code.to_i
      when 200..299
        JSON.parse(body_utf8)
      when 404
        error_message = extract_error_message(body_utf8) || "Entreprise non trouvée"
        add_error(error_message)
        Rails.logger.error "Entreprise non trouvée"
        nil
      when 429
        error_message = extract_error_message(body_utf8) || "Limite de taux d'appels dépassée"
        add_error(error_message)
        Rails.logger.error "Limite de taux d'appels dépassée"
        nil
      when 500..599
        error_message = extract_error_message(body_utf8) || "Erreur du serveur API"
        add_error(error_message)
        Rails.logger.error "Erreur serveur API Recherche Entreprises: #{response.code} - #{body_utf8}"
        nil
      else
        error_message = extract_error_message(body_utf8) || "Erreur API inattendue"
        add_error(error_message)
        Rails.logger.error "Erreur API Recherche Entreprises: #{response.code} - #{body_utf8}"
        nil
      end
    rescue JSON::ParserError => e
      add_error("Réponse API invalide")
      Rails.logger.error "Erreur de parsing JSON: #{e.message}"
      nil
    end

    def extract_error_message(body)
      parsed = JSON.parse(body)
      parsed["erreur"] if parsed.is_a?(Hash) && parsed["erreur"]
    rescue JSON::ParserError
      nil
    end

    def add_error(message)
      @errors << message
    end
  end
end
