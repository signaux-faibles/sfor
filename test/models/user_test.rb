require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup do
    @user = users(:user_crp_paris)
  end

  test "non_codefi_network should return the non-CODEFI network" do
    assert_equal networks(:network_crp), @user.non_codefi_network
  end

  test "password_complexity adds localized error for weak password" do
    user = users(:user_crp_paris)
    user.password = "short"
    user.password_confirmation = "short"

    assert_not user.valid?
    assert_includes user.errors.full_messages_for(:password),
                    "Mot de passe #{I18n.t('activerecord.errors.models.user.attributes.password.complexity')}"
  end

  test "reset_two_factor! clears TOTP state" do
    enable_two_factor!(@user)
    @user.generate_otp_backup_codes!
    @user.save!

    @user.reset_two_factor!

    assert_not @user.otp_required_for_login?
    assert_nil @user.otp_secret
    assert_nil @user.consumed_timestep
    assert_empty @user.otp_backup_codes
  end

  test "otp_provisioning_uri includes the issuer" do
    enable_two_factor!(@user)

    uri = @user.otp_provisioning_uri(@user.email, issuer: "Signaux Faibles")

    assert_match %r{\Aotpauth://totp/}, uri
    assert_includes uri, "Signaux"
    assert_includes uri, "test%40crp_paris.com"
  end
end
