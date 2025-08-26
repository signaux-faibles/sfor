require "net/http"
require "uri"
require "json"

module Api
  class RechercheEntreprisesApiService
    BASE_URL = "https://recherche-entreprises.api.gouv.fr"

    attr_reader :siren, :errors

    def initialize(siren:)
      @siren = siren
      @errors = []
    end

    def search_company
      return nil unless valid_siren?

      endpoint = "/search"
      params = { q: @siren }

      response = make_request(endpoint, params)

      # Return the first result since we're searching by SIREN (should be unique)
      response&.dig("results")&.first
    end

    def success?
      @errors.empty?
    end

    def failure?
      !success?
    end

    private

    def valid_siren?
      return false unless @siren.present?

      # SIREN must be exactly 9 digits
      siren_cleaned = @siren.to_s.gsub(/\D/, "") # Remove non-digits

      if siren_cleaned.length != 9
        add_error("SIREN invalide pour Recherche Entreprises: '#{@siren}' (longueur: #{siren_cleaned.length}, attendu: 9)")
        return false
      end

      @siren = siren_cleaned # Use cleaned version
      Rails.logger.debug { "SIREN valide pour Recherche Entreprises: #{@siren}" }
      true
    end

    def make_request(endpoint, params = {})
      uri = URI("#{BASE_URL}#{endpoint}")
      uri.query = URI.encode_www_form(params) if params.any?

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

      handle_response(response)
    rescue StandardError => e
      add_error("Erreur de connexion à l'API Recherche Entreprises: #{e.message}")
      Rails.logger.error "#{self.class.name}: #{e.message}"
      nil
    end

    def handle_response(response)
      case response.code.to_i
      when 200..299
        JSON.parse(response.body)
      when 404
        add_error("Entreprise non trouvée")
        Rails.logger.error "Entreprise non trouvée pour le SIREN #{@siren}"
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
