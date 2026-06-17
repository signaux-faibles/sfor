# frozen_string_literal: true

require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:user_crp_paris)
  end

  test "acknowledge_confidentiality saves timestamp" do
    sign_in @user
    @user.update_column(:last_confidentiality_acknowledged_at, nil)

    post acknowledge_confidentiality_users_path, as: :json

    assert_response :success
    assert_not_nil @user.reload.last_confidentiality_acknowledged_at
  end

  test "home page includes confidentiality modal when should show" do
    sign_in @user
    @user.update_column(:last_confidentiality_acknowledged_at, nil)

    get home_path

    assert_response :success
    assert_includes response.body, 'id="sf-confidentiality-modal"'
  end

  test "home page omits confidentiality modal when recently acknowledged" do
    sign_in @user
    @user.update_column(:last_confidentiality_acknowledged_at, Time.current)

    get home_path

    assert_response :success
    assert_not_includes response.body, 'id="sf-confidentiality-modal"'
  end
end
