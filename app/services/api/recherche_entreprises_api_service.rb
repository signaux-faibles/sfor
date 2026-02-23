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

    def make_request(endpoint, params = {})
      uri = build_uri(endpoint, normalize_params(params))
      response = perform_get(uri)
      handle_response(response)
    rescue StandardError => e
      add_error("Erreur de connexion à l'API Recherche Entreprises: #{e.message}")
      nil
    end

    def handle_response(response)
      body = normalized_body(response.body)

      case response.code.to_i
      when 200..299
        JSON.parse(body)
      when 404
        handle_error_response(body, "Entreprise non trouvée")
      when 429
        handle_error_response(body, "Limite de taux d'appels dépassée")
      when 500..599
        handle_error_response(body, "Erreur du serveur API")
      else
        handle_error_response(body, "Erreur API inattendue")
      end
    rescue JSON::ParserError
      add_error("Réponse API invalide")
      nil
    end

    def normalize_params(params)
      params = params.to_h if params.respond_to?(:to_h)
      params.reject { |_k, v| v.blank? || (v.is_a?(Array) && v.compact_blank.empty?) }
    end

    def build_uri(endpoint, params)
      uri = URI("#{BASE_URL}#{endpoint}")
      uri.query = URI.encode_www_form(params) if params.any?
      uri
    end

    def perform_get(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      http.open_timeout = 30
      http.read_timeout = 30

      request = Net::HTTP::Get.new(uri)
      request["User-Agent"] = "SignauxFaibles/#{Rails.env} (Ruby/#{RUBY_VERSION}; Rails/#{Rails.version})"
      request["Accept"] = "application/json"

      http.request(request)
    end

    def normalized_body(body)
      body_utf8 = body.to_s.force_encoding("UTF-8")
      return body_utf8 if body_utf8.valid_encoding?

      body_utf8.encode("UTF-8", invalid: :replace, undef: :replace)
    end

    def handle_error_response(body, fallback_message)
      add_error(extract_error_message(body) || fallback_message)
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
