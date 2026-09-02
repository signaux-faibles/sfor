class Users::TwoFactorController < ApplicationController
  include PendingTwoFactor

  layout "devise"
  skip_before_action :authenticate_user!
  skip_before_action :check_user_segment
  before_action :require_pending_two_factor_user
  before_action :redirect_enrolled_user_to_verify, only: %i[setup confirm]
  before_action :redirect_unenrolled_user_to_setup, only: %i[verify validate]
  before_action :redirect_to_backup_codes_if_pending, only: %i[verify validate]
  before_action :require_pending_backup_codes, only: %i[backup_codes acknowledge_backup_codes]

  def setup; end

  def confirm
    user = pending_two_factor_user
    if user.validate_and_consume_otp!(otp_attempt)
      codes = user.generate_otp_backup_codes!
      user.otp_required_for_login = true
      user.save!
      store_pending_backup_codes(codes)
      redirect_to backup_codes_two_factor_path, status: :see_other
    else
      render_invalid_otp(:setup)
    end
  end

  def backup_codes
    @backup_codes = pending_backup_codes
  end

  def acknowledge_backup_codes
    complete_two_factor_sign_in!(pending_two_factor_user)
    redirect_to after_sign_in_path_for(current_user), notice: t("two_factor.enrolled"), status: :see_other
  end

  def verify; end

  def validate
    if consume_two_factor_attempt!(pending_two_factor_user, otp_attempt)
      complete_two_factor_sign_in!(pending_two_factor_user)
      redirect_to after_sign_in_path_for(current_user), notice: t("devise.sessions.signed_in"), status: :see_other
    else
      handle_failed_otp_attempt
    end
  end

  private

  def require_pending_two_factor_user
    if user_signed_in?
      redirect_to after_sign_in_path_for(current_user), status: :see_other
      return
    end

    return if pending_two_factor_user

    clear_pending_two_factor!
    redirect_to new_user_session_path, alert: t("two_factor.session_expired"), status: :see_other
  end

  def redirect_enrolled_user_to_verify
    redirect_to verify_two_factor_path, status: :see_other if pending_two_factor_user.otp_required_for_login?
  end

  def redirect_unenrolled_user_to_setup
    redirect_to setup_two_factor_path, status: :see_other unless pending_two_factor_user.otp_required_for_login?
  end

  def redirect_to_backup_codes_if_pending
    redirect_to backup_codes_two_factor_path, status: :see_other if pending_backup_codes.present?
  end

  def require_pending_backup_codes
    return if pending_backup_codes.present?

    if pending_two_factor_user.otp_required_for_login?
      redirect_to verify_two_factor_path, status: :see_other
    else
      redirect_to setup_two_factor_path, status: :see_other
    end
  end

  def consume_two_factor_attempt!(user, code)
    return false if code.blank?

    user.validate_and_consume_otp!(code) || user.invalidate_otp_backup_code!(code)
  end

  def handle_failed_otp_attempt
    increment_two_factor_attempts!
    if two_factor_attempts_exceeded?
      clear_pending_two_factor!
      redirect_to new_user_session_path, alert: t("two_factor.too_many_attempts"), status: :see_other
    else
      render_invalid_otp(:verify)
    end
  end

  def render_invalid_otp(view)
    @otp_error = t("two_factor.invalid_code")
    render view, status: :unprocessable_entity
  end

  def otp_attempt
    params[:otp_attempt].to_s.gsub(/\s+/, "")
  end
end
