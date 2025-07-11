class Users::SessionsController < Devise::SessionsController
  skip_before_action :verify_authenticity_token, only: [:create]

  def new
    if user_signed_in?
      redirect_to root_path
    else
      # Store the current visit token in session so it persists across redirects
      session[:pending_ahoy_visit] = cookies[:ahoy_visit] if cookies[:ahoy_visit].present?

      redirect_to ENV.fetch("VUE_APP_FRONTEND_URL", nil).to_s, allow_other_host: true
    end
  end

  def create # rubocop:disable Metrics/MethodLength
    token = params[:token]
    decoded_token = decode_token(token)

    if decoded_token
      user = find_or_create_user(decoded_token)
      if user.active_for_authentication?
        sign_in(resource_name, user)

        # Update the current Ahoy visit with the user ID
        update_current_visit_user(user)

        render json: { success: true }
      else
        render json: { error: "Votre compte est inactif" }, status: :unauthorized
      end
    else
      render json: { error: "Invalid token" }, status: :unauthorized
    end
  end

  def destroy
    super do
      return redirect_to "#{ENV.fetch('VUE_APP_FRONTEND_URL', nil)}/#/logout", allow_other_host: true
    end
  end

  private

  def decode_token(token)
    JWT.decode(token, nil, false).first
  rescue JWT::DecodeError
    nil
  end

  def find_or_create_user(decoded_token) # rubocop:disable Metrics/MethodLength
    user_info = {
      email: decoded_token["email"],
      first_name: decoded_token["given_name"],
      last_name: decoded_token["family_name"]
    }

    user = User.find_or_create_by(email: user_info[:email]) do |new_user|
      new_user.first_name = user_info[:first_name]
      new_user.last_name = user_info[:last_name]
      new_user.password = Devise.friendly_token[0, 20]
    end

    update_user_roles(user, decoded_token)
    user
  end

  def update_user_roles(user, decoded_token)
    roles = decoded_token.dig("resource_access", "signauxfaibles", "roles") || []
    roles_from_db = Role.where(name: roles)
    user.roles = roles_from_db
  end

  def update_current_visit_user(user)
    # Get the current visit token from cookies or session
    visit_token = cookies[:ahoy_visit] || session[:pending_ahoy_visit]

    return if visit_token.blank?

    # Find and update the current visit with the user ID
    current_visit = Ahoy::Visit.find_by(visit_token: visit_token)
    current_visit.update(user: user) if current_visit && current_visit.user_id.nil?

    # Clean up the session after using it
    session.delete(:pending_ahoy_visit)
  end
end
