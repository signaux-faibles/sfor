class Users::SessionsController < Devise::SessionsController
  skip_before_action :verify_authenticity_token, only: :destroy
  def new
    respond_to do |format|
      format.html { render 'users/sessions/new' }
    end
  end

  def destroy
    id_token = current_user.id_token
    # Signing out from Rails/Devise
    sign_out(current_user)
    @id_token = id_token
    @redirect_uri = ENV['KEYCLOAK_POST_LOGOUT_REDIRECT_URI']
    @keycloak_host = "https://#{ENV['KEYCLOAK_HOST']}"
    # Rendering a view which includes javascript which will make the call to keycloak
    # This way rails won't be able to add its csrf and turbo headers which keycloak don't like
    render 'users/sessions/redirect_to_keycloak_logout'
  end
end
