require "net/http"
require "uri"
require "json"
require "jwt"

class SireneApiService
  BASE_URL = Rails.env.production? ? "https://entreprise.api.gouv.fr" : "https://staging.entreprise.api.gouv.fr"

  def initialize(siret)
    @siret = siret
    @token = ENV.fetch("API_ENTREPRISES_TOKEN", nil)
    @recipient = ENV.fetch("API_ENTREPRISES_RECIPIENT", nil)
  end

  def fetch_establishment
    return nil unless @token && @recipient

    # Vérification du token JWT
    begin
      decoded_token = JWT.decode(@token, nil, false)
      expiration = Time.at(decoded_token[0]["exp"])
      if expiration < Time.now
        Rails.logger.error "Token JWT expiré"
        return nil
      end
    rescue JWT::DecodeError => e
      Rails.logger.error "Erreur de décodage du token JWT: #{e.message}"
      return nil
    end

    # Construction de l'URL avec les paramètres
    endpoint = "/v3/insee/sirene/etablissements/diffusibles/#{@siret}"
    params = {
      recipient: @recipient,
      context: "Signaux Faibles",
      object: "Consultation de données"
    }
    uri = URI("#{BASE_URL}#{endpoint}")
    uri.query = URI.encode_www_form(params)

    # Configuration de la requête HTTP
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER

    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{@token}"
    request["User-Agent"] = "SignauxFaibles/#{Rails.env} (Ruby/#{RUBY_VERSION}; Rails/#{Rails.version})"
    request["Accept"] = "*/*"
    request["Cache-Control"] = "no-cache"
    request["Host"] = "entreprise.api.gouv.fr"

    # Exécution de la requête
    response = http.request(request)

    if response.is_a?(Net::HTTPSuccess)
      JSON.parse(response.body)
    else
      Rails.logger.error "Erreur API Sirene: #{response.code} - #{response.body}"
      nil
    end
  rescue StandardError => e
    Rails.logger.error "Erreur lors de la requête API Sirene: #{e.message}"
    nil
  end
end
