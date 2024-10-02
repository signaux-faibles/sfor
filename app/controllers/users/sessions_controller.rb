class Users::SessionsController < Devise::SessionsController
  skip_before_action :verify_authenticity_token, only: [:create]

  def create
    token = params[:token]
    decoded_token = decode_token(token)
    puts decoded_token
    if decoded_token
      user = find_or_create_user(decoded_token)
      if user.active_for_authentication?
        sign_in(resource_name, user)
        render json: { success: true }
      else
        render json: { error: 'Votre compte est inactif' }, status: :unauthorized
      end
    else
      render json: { error: 'Invalid token' }, status: :unauthorized
    end
  end

  private

  def decode_token(token)
    JWT.decode(token, nil, false).first
  rescue JWT::DecodeError
    nil
  end

  def find_or_create_user(decoded_token)
    user_info = {
      email: decoded_token['email'],
      first_name: decoded_token['given_name'],
      last_name: decoded_token['family_name']
    }

    user = User.find_or_create_by(email: user_info[:email]) do |user|
      user.first_name = user_info[:first_name]
      user.last_name = user_info[:last_name]
      user.password = Devise.friendly_token[0, 20]
    end

    update_user_roles(user, decoded_token)
    user
  end

  def update_user_roles(user, decoded_token)
    roles = decoded_token.dig('resource_access', 'signauxfaibles', 'roles') || []
    roles_from_db = Role.where(name: roles)
    user.roles = roles_from_db
  end
end