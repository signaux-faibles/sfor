module PendingTwoFactor
  extend ActiveSupport::Concern

  PENDING_USER_ID = :pending_2fa_user_id
  PENDING_EXPIRES_AT = :pending_2fa_expires_at
  PENDING_ATTEMPTS = :pending_2fa_attempts
  PENDING_BACKUP_CODES = :pending_2fa_backup_codes

  PENDING_TTL = 10.minutes
  MAX_OTP_ATTEMPTS = 5

  included do
    helper_method :pending_two_factor_user, :pending_backup_codes
  end

  def start_pending_two_factor!(user)
    session[PENDING_USER_ID] = user.id
    session[PENDING_EXPIRES_AT] = PENDING_TTL.from_now.iso8601
    session[PENDING_ATTEMPTS] = 0
    session.delete(PENDING_BACKUP_CODES)
  end

  def pending_two_factor_user
    return if session[PENDING_USER_ID].blank?
    return if pending_two_factor_expired?

    @pending_two_factor_user ||= User.kept.find_by(id: session[PENDING_USER_ID])
  end

  def pending_two_factor_expired?
    expires_at = session[PENDING_EXPIRES_AT]
    return true if expires_at.blank?

    Time.zone.parse(expires_at) < Time.zone.now
  end

  def store_pending_backup_codes(codes)
    session[PENDING_BACKUP_CODES] = codes
  end

  def pending_backup_codes
    session[PENDING_BACKUP_CODES]
  end

  def increment_two_factor_attempts!
    session[PENDING_ATTEMPTS] = pending_two_factor_attempts + 1
  end

  def pending_two_factor_attempts
    session[PENDING_ATTEMPTS].to_i
  end

  def two_factor_attempts_exceeded?
    pending_two_factor_attempts >= MAX_OTP_ATTEMPTS
  end

  def complete_two_factor_sign_in!(user)
    clear_pending_two_factor!
    sign_in(:user, user)
  end

  def clear_pending_two_factor!
    session.delete(PENDING_USER_ID)
    session.delete(PENDING_EXPIRES_AT)
    session.delete(PENDING_ATTEMPTS)
    session.delete(PENDING_BACKUP_CODES)
    @pending_two_factor_user = nil
  end
end
