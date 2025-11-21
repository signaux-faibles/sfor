module IntegrationTestHelpers
  def login_user(user)
    # Use standard Devise email/password authentication
    post "/users/sign_in", params: {
      user: {
        email: user.email,
        password: "password"
      }
    }
    # Devise redirects after successful login (302), so we check for redirect or success
    assert_response :redirect,
                    "Failed to sign in user #{user.email}. Response: #{@response.status} - #{@response.body[0..200]}"

    follow_redirect! if @response.redirect?
  end
end
