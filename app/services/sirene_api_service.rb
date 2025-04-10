require "net/http"
require "uri"
require "json"
require "jwt"

class SireneApiService
  def initialize(siret)
    @siret = siret
    @token = ENV.fetch("API_ENTREPRISES_TOKEN", nil)
    @recipient = ENV.fetch("API_ENTREPRISES_RECIPIENT", nil)
  end

  def fetch_establishment
    return nil unless @token && @recipient

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

    base_url = "https://entreprise.api.gouv.fr"
    endpoint = "/v3/insee/sirene/etablissements/diffusibles/#{@siret}"
    params = {
      recipient: @recipient,
      context: "Signaux Faibles",
      object: "Consultation de données"
    }
    query_string = params.map { |k, v| "#{k}=#{CGI.escape(v)}" }.join("&")
    url = "#{base_url}#{endpoint}?#{query_string}"

    curl_command = "curl -s -X GET '#{url}' " \
                   "-H 'Authorization: Bearer #{@token}' " \
                   "-H 'User-Agent: PostmanRuntime/7.43.3' " \
                   "-H 'Accept: */*' " \
                   "-H 'Cache-Control: no-cache' " \
                   "-H 'Postman-Token: aa84b9b7-2227-4d29-bc91-57da21db8e7e' " \
                   "-H 'Host: entreprise.api.gouv.fr' " \
                   "-H 'Accept-Encoding: gzip, deflate, br' " \
                   "-H 'Connection: keep-alive'"

    response = `#{curl_command}`
    begin
      data = JSON.parse(response)
      if data["errors"]
        Rails.logger.error "Erreur API Sirene: #{data['errors']}"
        nil
      else
        data
      end
    rescue JSON::ParserError => e
      Rails.logger.error "Erreur de parsing JSON: #{e.message}"
      nil
    end
  end
end
