# frozen_string_literal: true

require "test_helper"

class CompaniesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:user_crp_paris)
    @company_paris = companies(:company_paris)
    @company_finistere = companies(:company_finistere)
  end

  test "show redirects to sign in when not authenticated" do
    get company_path(@company_paris.siren)

    assert_redirected_to new_user_session_path
  end

  test "show returns success when authenticated and company exists" do
    sign_in @user

    get company_path(@company_paris.siren)

    assert_response :success
  end

  test "show displays company raison_sociale" do
    sign_in @user

    get company_path(@company_paris.siren)

    assert_response :success
    assert_includes @response.body, @company_paris.raison_sociale
  end

  test "show displays company siren in page" do
    sign_in @user

    get company_path(@company_paris.siren)

    assert_response :success
    assert_includes @response.body, @company_paris.siren
  end

  test "show redirects when company does not exist" do
    sign_in @user

    get company_path("000000000")

    assert_redirected_to home_path
    assert_equal "Cette fiche entreprise n'existe pas dans SignauxFaibles", flash[:alert]
  end

  test "detection_widget returns success when company has score entry" do
    sign_in @user

    get detection_widget_company_path(@company_paris.siren), headers: { "Accept" => "text/html" }

    assert_response :success
  end

  test "establishments_widget returns success" do
    sign_in @user

    get establishments_widget_company_path(@company_paris.siren), headers: { "Accept" => "text/html" }

    assert_response :success
  end
end
