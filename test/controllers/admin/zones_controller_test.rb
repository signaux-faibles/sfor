# frozen_string_literal: true

require "test_helper"

class Admin::ZonesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:user_admin_sf)
    @non_admin = users(:user_crp_paris)
    @zone = zones(:support_page_body)
  end

  test "index redirects non admin" do
    sign_in @non_admin

    get admin_zones_path

    assert_redirected_to root_url
  end

  test "index renders for admin" do
    sign_in @admin

    get admin_zones_path

    assert_response :success
    assert_includes @response.body, "Zones editables"
    assert_includes @response.body, @zone.key
  end

  test "edit renders for admin" do
    sign_in @admin

    get edit_admin_zone_path(@zone)

    assert_response :success
    assert_includes @response.body, "Contenu (Markdown)"
  end

  test "create zone" do
    sign_in @admin

    assert_difference("Zone.count", 1) do
      post admin_zones_path, params: {
        zone: {
          key: "new_marketing_block",
          content: "Contenu de test"
        }
      }
    end

    assert_redirected_to admin_zones_path
  end

  test "update zone content" do
    sign_in @admin

    patch admin_zone_path(@zone), params: {
      zone: {
        content: "Nouveau contenu **markdown**."
      }
    }

    assert_redirected_to admin_zones_path
    @zone.reload
    assert_equal "Nouveau contenu **markdown**.", @zone.content
  end
end
