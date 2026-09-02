# frozen_string_literal: true

require "test_helper"

class Devise::SessionsControllerTest < ActionDispatch::IntegrationTest
  test "new login page exposes initial focus anchor above flash and no email autofocus" do
    get new_user_session_path

    assert_response :success
    assert_select "#page-start[data-controller='initial-focus'][tabindex='-1']"
    assert_select "#page-start + #flash"
    assert_select "#user_email-format", text: /Format attendu : nom.prenom@domaine.fr/
    assert_select "#user_email[aria-describedby=?]", "user_email-format"
    assert_select "#user_password-format", text: /12 caractères minimum/ # pragma: allowlist secret
    assert_select "#user_password[aria-describedby=?]", "user_password-format" # pragma: allowlist secret
    assert_select "input[type=email][autofocus]", false
    assert_select "div[role=alert]", false
    assert_select "p", text: /code de double authentification/
    assert_select "input[name='user[remember_me]']", false
  end

  test "failed login shows inline error on email field without top flash" do
    post user_session_path, params: { user: { email: "wrong@example.com", password: "WrongPass1!" } } # pragma: allowlist secret

    assert_redirected_to new_user_session_path
    follow_redirect!

    assert_response :success
    assert_select "#flash div[role=alert]", false
    assert_select "#user_email-error", text: "Email et/ou mot de passe incorrect(s)."
    assert_select "#user_email[aria-describedby=?]", "user_email-format user_email-error"
    assert_select "#user_email[aria-invalid=?]", "true"
    assert_select ".fr-input-group--error #user_email"
  end

  test "unauthenticated access redirects to login with flash below focus anchor" do
    get home_path

    assert_redirected_to new_user_session_path
    follow_redirect!

    assert_response :success
    assert_select "#page-start + #flash div[role=alert]", text: /Vous devez vous connecter/
  end
end
