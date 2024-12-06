module IntegrationTestHelpers
  def login_user(user)
    token_payload = {
      'email' => user.email,
      'first_name' => user.first_name,
      'last_name' => user.last_name
    }
    token = JWT.encode(token_payload, nil, 'none')

    # Simulating Vue.js token-based sign-in (AP to NP)
    post '/users/sign_in', params: { token: token }
    assert_response :success, "Failed to sign in user #{user.email}"

    follow_redirect! if @response.redirect?
  end
end