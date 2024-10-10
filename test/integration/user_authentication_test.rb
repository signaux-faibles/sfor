require 'test_helper'

class UserAuthenticationTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:user_crp_paris)

    token_payload = {
      'email' => @user.email,
      'first_name' => @user.first_name,
      'last_name' => @user.last_name
    }
    @token = JWT.encode(token_payload, nil, 'none')
  end

  test 'user can authenticate via token and access the homepage' do
    # Simulating what happens when logging from Vue js app
    post '/users/sign_in', params: { token: @token }

    assert_response :success
    assert_includes @response.body, 'success'

    # Simulate the redirect which is actyally done by Vue js
    get root_path

    assert_response :success
    assert_includes @response.body, 'Accueil de l\'application'
  end
end


