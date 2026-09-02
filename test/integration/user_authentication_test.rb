require "test_helper"

class UserAuthenticationTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:user_crp_paris)
  end

  test "user can authenticate and access the homepage" do
    login_user(@user)

    get root_path
    assert_response :success
    assert_includes @response.body, "Réinitialiser les filtres"
  end

  test "password-only login is not enough when 2FA is mandatory" do # pragma: allowlist secret
    password = assign_user_password(@user) # pragma: allowlist secret

    post user_session_path, params: { user: { email: @user.email, password: password } } # pragma: allowlist secret

    assert_redirected_to setup_two_factor_path
    get root_path
    assert_redirected_to new_user_session_path
  end
end
