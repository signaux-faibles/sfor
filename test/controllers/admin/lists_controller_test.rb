# frozen_string_literal: true

require "test_helper"

class Admin::ListsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:user_admin_sf)
    @non_admin = users(:user_crp_paris)
    @list = lists(:list_test_2025)
  end

  test "index redirects non admin" do
    sign_in @non_admin

    get admin_lists_path

    assert_redirected_to root_url
  end

  test "index renders for admin" do
    sign_in @admin

    get admin_lists_path

    assert_response :success
    assert_includes @response.body, "Précision des alertes par liste"
    assert_includes @response.body, @list.label
  end

  test "edit renders for admin" do
    sign_in @admin

    get edit_admin_list_path(@list)

    assert_response :success
    assert_includes @response.body, "Précision alerte élevée"
    assert_includes @response.body, "Précision alerte modérée"
  end

  test "update list precision values" do
    sign_in @admin

    patch admin_list_path(@list), params: {
      list: {
        precision_alerte_elevee: 82.5,
        precision_alerte_moderee: 67.25
      }
    }

    assert_redirected_to admin_lists_path
    @list.reload
    assert_equal BigDecimal("82.5"), @list.precision_alerte_elevee
    assert_equal BigDecimal("67.25"), @list.precision_alerte_moderee
  end

  test "update rejects invalid precision values" do
    sign_in @admin

    original_elevee = @list.precision_alerte_elevee
    original_moderee = @list.precision_alerte_moderee

    patch admin_list_path(@list), params: {
      list: {
        precision_alerte_elevee: 120,
        precision_alerte_moderee: -5
      }
    }

    assert_response :unprocessable_entity
    @list.reload
    assert_equal original_elevee, @list.precision_alerte_elevee
    assert_equal original_moderee, @list.precision_alerte_moderee
  end
end
