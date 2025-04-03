# frozen_string_literal: true

# Handles OAuth authentication for User models
# Manages user creation and role updates from OAuth providers
module User::Omniauthable
  extend ActiveSupport::Concern

  class_methods do
    def from_omniauth(auth)
      Rails.logger.debug { "auth info: #{auth.inspect}" }

      user = find_or_create_user(auth)
      user.update_roles_from_auth(auth)
      user
    end

    def find_or_create_user(auth)
      where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
        user.email = auth.info.email
        user.password = Devise.friendly_token[0, 20]
        user.id_token = auth.credentials.id_token
      end
    end
  end

  def update_roles_from_auth(auth)
    Rails.logger.debug "auth credentials"
    Rails.logger.debug auth.credentials
    roles = extract_roles_from_token(auth.credentials.token)
    Rails.logger.debug roles.inspect
    self.roles = roles.map { |role_name| Role.find_or_create_by(name: role_name) }
    save!
  end

  private

  def extract_roles_from_token(token)
    decoded_token = JWT.decode(token, nil, false)
    resource_access = decoded_token.first["resource_access"]
    return [] unless resource_access && resource_access["signauxfaibles"]

    resource_access["signauxfaibles"]["roles"]
  rescue StandardError
    []
  end
end
