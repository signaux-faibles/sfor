module IntegrationTestHelpers
  TEST_USER_PASSWORD = "Test1234#dev".freeze # pragma: allowlist secret

  def login_user(user)
    sign_in user
  end

  def assign_user_password(user, password = TEST_USER_PASSWORD) # pragma: allowlist secret
    user.password = password # pragma: allowlist secret
    user.password_confirmation = password # pragma: allowlist secret
    user.save!
    password # pragma: allowlist secret
  end

  def enable_two_factor!(user)
    user.update!(
      otp_secret: User.generate_otp_secret,
      otp_required_for_login: true,
      consumed_timestep: nil
    )
    user
  end
end
