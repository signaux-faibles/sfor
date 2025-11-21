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
end
