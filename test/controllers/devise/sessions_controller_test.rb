# frozen_string_literal: true

require "test_helper"

class Devise::SessionsControllerTest < ActionDispatch::IntegrationTest
  test "new login page exposes initial focus anchor and no email autofocus" do
    get new_user_session_path

    assert_response :success
    assert_select "#page-start[data-controller='initial-focus'][tabindex='-1']"
    assert_select "input[type=email][autofocus]", false
    assert_select "div[role=alert]", false
  end

  test "failed login renders flash message with alert role" do
    post user_session_path, params: { user: { email: "wrong@example.com", password: "WrongPass1!" } }

    assert_response :unprocessable_content
    assert_select "div[role=alert]"
  end
end
