class Users::SessionsController < Devise::SessionsController
  include PendingTwoFactor

  # Devise and ApplicationController callbacks call current_user / warden.authenticate,
  # which would sign the user in from email+credentials params before TOTP.
  skip_before_action :require_no_authentication, only: :create
  skip_around_action :set_time_zone, only: :create
  skip_before_action :set_sentry_user, only: :create
  skip_before_action :set_notification_flash, only: :create
  skip_after_action :track_action, only: :create

  def new
    clear_pending_two_factor!
    super
  end

  def create
    if warden.authenticated?(scope: :user)
      redirect_to after_sign_in_path_for(warden.user(:user)), status: :see_other
      return
    end

    user = find_user_from_sign_in_params

    if user&.valid_password?(sign_in_password) && user.active_for_authentication? # pragma: allowlist secret
      start_pending_two_factor!(user)
      redirect_to after_password_path_for(user), status: :see_other # pragma: allowlist secret
    else
      flash[:sign_in_error] = I18n.t("devise.failure.invalid")
      redirect_to new_user_session_path, status: :see_other
    end
  end

  private

  def find_user_from_sign_in_params
    email = params.dig(:user, :email).presence
    return if email.blank?

    User.find_for_authentication(email: email)
  end

  def sign_in_password # pragma: allowlist secret
    params.dig(:user, :password) # pragma: allowlist secret
  end

  def after_password_path_for(user) # pragma: allowlist secret
    if user.otp_required_for_login?
      verify_two_factor_path
    else
      user.update!(otp_secret: User.generate_otp_secret, consumed_timestep: nil)
      setup_two_factor_path
    end
  end
end
