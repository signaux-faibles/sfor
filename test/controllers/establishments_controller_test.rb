# frozen_string_literal: true

require "test_helper"

class EstablishmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:user_crp_paris)
    @establishment_paris = establishments(:establishment_paris)
    @establishment_finistere = establishments(:establishment_finistere)
  end

  test "show redirects to sign in when not authenticated" do
    get establishment_path(@establishment_paris.siret)

    assert_redirected_to new_user_session_path
  end

  test "show returns success when authenticated and establishment exists" do
    sign_in @user

    get establishment_path(@establishment_paris.siret)

    assert_response :success
  end

  test "show displays establishment raison_sociale (from company)" do
    sign_in @user

    get establishment_path(@establishment_paris.siret)

    assert_response :success
    # Establishment#raison_sociale delegates to company
    assert_includes @response.body, @establishment_paris.raison_sociale
  end

  test "show displays establishment siret in page" do
    sign_in @user

    get establishment_path(@establishment_paris.siret)

    assert_response :success
    assert_includes @response.body, @establishment_paris.siret
  end

  test "show returns not found when establishment does not exist" do
    sign_in @user

    get establishment_path("00000000000000")

    assert_response :not_found
  end

  test "establishment_trackings_list_widget returns success" do
    sign_in @user

    get establishment_trackings_list_widget_establishment_path(@establishment_paris.siret),
        headers: { "Accept" => "text/html" }

    assert_response :success
  end
end
