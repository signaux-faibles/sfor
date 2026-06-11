# frozen_string_literal: true

require "test_helper"

class Devise::PasswordsControllerTest < ActionDispatch::IntegrationTest
  test "forgot password page uses full-width wrappable submit button" do
    get new_user_password_path

    assert_response :success
    assert_select ".fr-btns-group--inline", false
    assert_select "button.fr-btn[type=submit]", text: /Envoyer les instructions de réinitialisation/
    assert_select "input[type=submit]", false
  end

  test "unknown email links error message to email field" do
    post user_password_path, params: { user: { email: "absolutely-unknown@example.com" } }

    assert_response :unprocessable_entity
    assert_select "#error_explanation", false
    assert_select "#user_email-error", text: "Email n'a pas été trouvé(e)"
    assert_select "#user_email[aria-describedby=?]", "user_email-format user_email-error"
    assert_select "#user_email[aria-invalid=?]", "true"
  end

  test "password edit page links format hints to fields" do
    user = users(:user_crp_paris)
    token = user.send(:set_reset_password_token)

    get edit_user_password_path(reset_password_token: token)

    assert_response :success
    assert_select "#user_password-format", text: /Exemple : Test1234#dev/
    assert_select "#user_password[aria-describedby=?]", "user_password-format"
    assert_select "#user_password_confirmation-format", text: /Saisissez à nouveau le même mot de passe/
    assert_select "#user_password_confirmation[aria-describedby=?]", "user_password_confirmation-format"
    assert_select "#error_explanation", false
  end

  test "password edit links validation errors with examples to each field" do
    user = users(:user_crp_paris)
    token = user.send(:set_reset_password_token)

    put user_password_path, params: {
      user: {
        reset_password_token: token,
        password: "alllowercase12",
        password_confirmation: "different"
      }
    }

    assert_response :unprocessable_entity
    assert_select "#error_explanation", false
    assert_select "#user_password-error", text: /par exemple : Test1234#dev/
    assert_select "#user_password[aria-describedby=?]", "user_password-format user_password-error"
    assert_select "#user_password[aria-invalid=?]", "true"
    assert_select "#user_password_confirmation-error", text: /doit être identique au mot de passe saisi/
    assert_select "#user_password_confirmation[aria-describedby=?]",
                  "user_password_confirmation-format user_password_confirmation-error"
    assert_select "#user_password_confirmation[aria-invalid=?]", "true"
  end
end
