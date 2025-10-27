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
      params = params.reject { |_k, v| v.blank? || (v.is_a?(Array) && v.reject(&:blank?).empty?) }

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

    def handle_response(response) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      case response.code.to_i
      when 200..299
        JSON.parse(response.body)
      when 404
        add_error("Entreprise non trouvée")
        Rails.logger.error "Entreprise non trouvée"
        nil
      when 429
        add_error("Limite de taux d'appels dépassée")
        Rails.logger.error "Limite de taux d'appels dépassée"
        nil
      when 500..599
        add_error("Erreur du serveur API")
        Rails.logger.error "Erreur serveur API Recherche Entreprises: #{response.code} - #{response.body}"
        nil
      else
        add_error("Erreur API inattendue")
        Rails.logger.error "Erreur API Recherche Entreprises: #{response.code} - #{response.body}"
        nil
      end
    rescue JSON::ParserError => e
      add_error("Réponse API invalide")
      Rails.logger.error "Erreur de parsing JSON: #{e.message}"
      nil
    end

    def add_error(message)
      @errors << message
    end
  end
end
