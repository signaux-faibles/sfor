require "test_helper"

class NotificationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:user_crp_paris)
    @notification_crp = notifications(:notification_crp)
    @notification_urssaf = notifications(:notification_urssaf)
  end

  test "index redirects to sign in when not authenticated" do
    get notifications_path

    assert_redirected_to new_user_session_path
  end

  test "index shows notifications for the user segment only" do
    sign_in @user

    get notifications_path

    assert_response :success
    assert_includes @response.body, @notification_crp.title
    assert_not_includes @response.body, @notification_urssaf.title
  end

  test "show marks a notification as read" do
    sign_in @user

    get notification_path(@notification_crp)

    assert_response :success
    notification_read = NotificationRead.find_by(user: @user, notification: @notification_crp)
    assert notification_read.present?
    assert notification_read.read_at.present?
  end
end
