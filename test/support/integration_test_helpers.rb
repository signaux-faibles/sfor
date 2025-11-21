module IntegrationTestHelpers
  def login_user(user)
    # Use standard Devise email/password authentication
    post "/users/sign_in", params: {
      user: {
        email: user.email,
        password: "password"
      }
    }
    assert_response :success, "Failed to sign in user #{user.email}"

    follow_redirect! if @response.redirect?
  end
end
