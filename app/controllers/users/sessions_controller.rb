class Users::SessionsController < Devise::SessionsController
  def create
    self.resource = warden.authenticate(auth_options)

    if resource
      set_flash_message!(:notice, :signed_in) if is_navigational_format?
      sign_in(resource_name, resource)
      yield resource if block_given?
      respond_with resource, location: after_sign_in_path_for(resource)
    else
      flash[:sign_in_error] = I18n.t("devise.failure.invalid")
      redirect_to new_user_session_path
    end
  end
end
