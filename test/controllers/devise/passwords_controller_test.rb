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
end
