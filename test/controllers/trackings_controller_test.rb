require "test_helper"

class TrackingsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get trackings_new_url
    assert_response :success
  end

  test "should get create" do
    get trackings_create_url
    assert_response :success
  end

  test "should get show" do
    get trackings_show_url
    assert_response :success
  end

  test "should get destroy" do
    get trackings_destroy_url
    assert_response :success
  end
end
