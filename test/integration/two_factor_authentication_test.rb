require "test_helper"

class TwoFactorAuthenticationTest < ActionDispatch::IntegrationTest
  setup do
    freeze_time
    @user = users(:user_crp_paris)
    @password = assign_user_password(@user) # pragma: allowlist secret
  end

  test "password sign in without 2FA setup redirects to enrollment and does not grant a session" do # pragma: allowlist secret
    post user_session_path, params: { user: { email: @user.email, password: @password } } # pragma: allowlist secret

    assert_redirected_to setup_two_factor_path
    follow_redirect!

    assert_response :success
    assert_select "h1", text: "Configurer la double authentification"
    assert_select ".sf-totp-qr svg"
    assert_select "code", text: /[A-Z2-7 ]+/

    get root_path
    assert_redirected_to new_user_session_path
  end

  test "enrolling with a valid TOTP then acknowledging backup codes signs the user in" do
    post user_session_path, params: { user: { email: @user.email, password: @password } } # pragma: allowlist secret
    follow_redirect!

    post confirm_two_factor_path, params: { otp_attempt: @user.reload.current_otp }

    assert_redirected_to backup_codes_two_factor_path
    follow_redirect!

    assert_response :success
    assert_select "h1", text: "Codes de secours"
    assert_select ".sf-totp-backup-codes li code", count: 10

    post acknowledge_backup_codes_two_factor_path

    assert_redirected_to root_path
    follow_redirect!
    assert_response :success
    assert @user.reload.otp_required_for_login?
    assert_equal 10, @user.otp_backup_codes.size
  end

  test "enrollment rejects an invalid TOTP" do
    post user_session_path, params: { user: { email: @user.email, password: @password } } # pragma: allowlist secret
    follow_redirect!

    post confirm_two_factor_path, params: { otp_attempt: "000000" }

    assert_response :unprocessable_entity
    assert_select "#otp_attempt-error", text: /Code invalide/
    assert_not @user.reload.otp_required_for_login?
  end

  test "enrolled user must provide a valid TOTP before accessing the app" do
    enable_two_factor!(@user)

    post user_session_path, params: { user: { email: @user.email, password: @password } } # pragma: allowlist secret

    assert_redirected_to verify_two_factor_path
    follow_redirect!
    assert_select "h1", text: "Double authentification"

    get root_path
    assert_redirected_to new_user_session_path

    post user_session_path, params: { user: { email: @user.email, password: @password } } # pragma: allowlist secret
    post validate_two_factor_path, params: { otp_attempt: @user.reload.current_otp }

    assert_redirected_to root_path
    follow_redirect!
    assert_response :success
  end

  test "enrolled user can sign in with a backup code once" do
    enable_two_factor!(@user)
    codes = @user.generate_otp_backup_codes!
    @user.save!
    code = codes.first

    post user_session_path, params: { user: { email: @user.email, password: @password } } # pragma: allowlist secret
    post validate_two_factor_path, params: { otp_attempt: code }

    assert_redirected_to root_path
    assert_equal 9, @user.reload.otp_backup_codes.size

    delete destroy_user_session_path
    post user_session_path, params: { user: { email: @user.email, password: @password } } # pragma: allowlist secret
    post validate_two_factor_path, params: { otp_attempt: code }

    assert_response :unprocessable_entity
    assert_select "#otp_attempt-error", text: /Code invalide/
  end

  test "reused TOTP is rejected" do
    enable_two_factor!(@user)
    otp = @user.current_otp

    post user_session_path, params: { user: { email: @user.email, password: @password } } # pragma: allowlist secret
    post validate_two_factor_path, params: { otp_attempt: otp }
    assert_redirected_to root_path

    delete destroy_user_session_path
    post user_session_path, params: { user: { email: @user.email, password: @password } } # pragma: allowlist secret
    post validate_two_factor_path, params: { otp_attempt: otp }

    assert_response :unprocessable_entity
    assert_select "#otp_attempt-error", text: /Code invalide/
  end

  test "too many invalid TOTP attempts send the user back to login" do
    enable_two_factor!(@user)

    post user_session_path, params: { user: { email: @user.email, password: @password } } # pragma: allowlist secret

    5.times do
      post validate_two_factor_path, params: { otp_attempt: "000000" }
    end

    assert_redirected_to new_user_session_path
    follow_redirect!
    assert_select ".fr-alert", text: /Trop de tentatives/

    get verify_two_factor_path
    assert_redirected_to new_user_session_path
  end

  test "two factor pages without a pending login redirect to sign in" do
    get setup_two_factor_path
    assert_redirected_to new_user_session_path

    get verify_two_factor_path
    assert_redirected_to new_user_session_path
  end
end
