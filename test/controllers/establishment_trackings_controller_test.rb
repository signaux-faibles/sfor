require 'test_helper'
class EstablishmentTrackingsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @establishment_tracking_paris = establishment_trackings(:establishment_tracking_paris)
    @establishment_tracking_paris_2 = establishment_trackings(:establishment_tracking_paris_2)
    @establishment_tracking_paris_3 = establishment_trackings(:establishment_tracking_paris_3)
    @establishment_tracking_finistere = establishment_trackings(:establishment_tracking_finistere)
    @establishment_tracking_paris_with_urssaf_referents = establishment_trackings(:establishment_tracking_paris_with_urssaf_referents)
    @establishment_tracking_paris_no_content = establishment_trackings(:establishment_tracking_paris_no_content)
    @establishment_paris = establishments(:establishment_paris)
    @establishment_paris_2 = establishments(:establishment_paris_2)
    @user_crp_paris = users(:user_crp_paris)
    @user_urssaf_paris = users(:user_urssaf_paris)
    @user_crp_paris_2 = users(:user_crp_paris_2)

    sign_in @user_crp_paris
  end

  test "should get index" do
    get establishment_trackings_url
    assert_response :success
    assert_includes response.body, @establishment_tracking_paris.establishment.raison_sociale
    assert_not_includes response.body, @establishment_tracking_finistere.establishment.raison_sociale
  end

  test "should show trackings where user is referent when my_tracking=1" do
    get establishment_trackings_url, params: { q: { my_tracking: "1" } }
    assert_response :success
    assert_includes response.body, @establishment_tracking_paris.establishment.raison_sociale
    assert_includes response.body, @establishment_tracking_paris_with_urssaf_referents.establishment.raison_sociale
    assert_not_includes response.body, @establishment_tracking_finistere.establishment.raison_sociale
  end

  test "should show trackings where user is participant when my_tracking=1" do
    @establishment_tracking_paris_with_urssaf_referents.participants << @user_crp_paris

    get establishment_trackings_url, params: { q: { my_tracking: "1" } }
    assert_response :success
    assert_includes response.body, @establishment_tracking_paris_with_urssaf_referents.establishment.raison_sociale
  end

  test "should show trackings where establishment department matches user departments when my_tracking=1" do
    get establishment_trackings_url, params: { q: { my_tracking: "1" } }
    assert_response :success
    assert_includes response.body, @establishment_tracking_paris_3.establishment.raison_sociale
  end

  test "should not show trackings from other departments when my_tracking=1" do
    get establishment_trackings_url, params: { q: { my_tracking: "1" } }
    assert_response :success
    assert_not_includes response.body, @establishment_tracking_finistere.establishment.raison_sociale
  end

  test "should show trackings from user's networks when my_tracking=network" do
    get establishment_trackings_url, params: { q: { my_tracking: "network" } }
    assert_response :success
    assert_includes response.body, @establishment_tracking_paris.establishment.raison_sociale
    assert_not_includes response.body, @establishment_tracking_finistere.establishment.raison_sociale
  end

  test "should show trackings where referents share the same network as current user when my_tracking=network" do
    get establishment_trackings_url, params: { q: { my_tracking: "network" } }
    assert_response :success
    assert_includes response.body, @establishment_tracking_paris_2.establishment.raison_sociale
  end

  test "should show trackings where participants share the same network as current user when my_tracking=network" do
    get establishment_trackings_url, params: { q: { my_tracking: "network" } }
    assert_response :success
    assert_includes response.body, @establishment_tracking_paris_3.establishment.raison_sociale
  end

  test "should get show" do
    get establishment_establishment_tracking_url(@establishment_paris, @establishment_tracking_paris)
    assert_response :success
    assert_includes response.body, @establishment_tracking_paris.establishment.raison_sociale
  end

  test "should get new" do
    get new_establishment_establishment_tracking_url(@establishment_paris)
    assert_response :success
  end

  test "should create establishment_tracking" do
    assert_difference('EstablishmentTracking.count') do
      post establishment_establishment_trackings_url(@establishment_paris_2), params: {
        establishment_tracking: {
          state: 'in_progress',
          start_date: Date.today,
          referent_ids: [@user_crp_paris.id],
          tracking_label_ids: [],
          user_action_ids: [],
          sector_ids: [],
          participant_ids: [],
          difficulty_ids: [],
          codefi_redirect_ids: []
        }
      }
    end

    assert_redirected_to @establishment_paris_2
    assert_equal 'L\'accompagnement a été créé avec succès.', flash[:success]
  end

  test "should not create establishment_tracking with invalid params" do
    assert_no_difference('EstablishmentTracking.count') do
      post establishment_establishment_trackings_url(@establishment_paris), params: {
        establishment_tracking: {
          state: nil,
          start_date: nil,
          referent_ids: [],
          tracking_label_ids: [],
          user_action_ids: [],
          sector_ids: [],
          participant_ids: [],
          difficulty_ids: [],
          codefi_redirect_ids: []
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should get edit" do
    get edit_establishment_establishment_tracking_url(@establishment_paris, @establishment_tracking_paris)
    assert_response :success
  end

  test "should update establishment_tracking" do
    patch establishment_establishment_tracking_url(@establishment_paris, @establishment_tracking_paris), params: {
      establishment_tracking: {
        state: 'completed',
        tracking_label_ids: [],
        user_action_ids: [],
        sector_ids: [],
        participant_ids: [],
        referent_ids: [@user_crp_paris.id],
        difficulty_ids: [],
        codefi_redirect_ids: []
      }
    }

    assert_redirected_to establishment_establishment_tracking_url(@establishment_paris, @establishment_tracking_paris)
    assert_equal 'L\'accompagnement a été mis à jour avec succès.', flash[:success]
  end

  test "should destroy establishment_tracking" do
    assert_difference('EstablishmentTracking.count', -1) do
      delete establishment_establishment_tracking_url(@establishment_paris, @establishment_tracking_paris)
    end

    assert_redirected_to @establishment_paris
    assert_equal 'L\'accompagnement a été supprimé avec succès.', flash[:success]
  end

  test "should get manage_contributors" do
    get manage_contributors_establishment_establishment_tracking_url(@establishment_paris, @establishment_tracking_paris)
    assert_response :success
  end

  test "should update contributors" do
    patch update_contributors_establishment_establishment_tracking_url(@establishment_paris, @establishment_tracking_paris), params: {
      establishment_tracking: {
        referent_ids: [@user_crp_paris.id],
        participant_ids: []
      }
    }

    assert_redirected_to establishment_establishment_tracking_url(@establishment_paris, @establishment_tracking_paris)
    assert_equal "Contributeurs mis à jour avec succès.", flash[:success]
  end

  test "should handle new_by_siret with existing establishment" do
    get new_establishment_tracking_by_siret_url, params: {
      siret: @establishment_paris.siret,
      code_departement: @establishment_paris.department.code
    }

    assert_redirected_to establishment_establishment_tracking_url(@establishment_paris, @establishment_tracking_paris)
  end

  test "should handle new_by_siret with non-existing establishment" do
    assert_difference('Establishment.count') do
      get new_establishment_tracking_by_siret_url, params: {
        siret: "12345678901234",
        denomination: "New Company",
        code_departement: @establishment_paris.department.code
      }
    end

    assert_redirected_to new_establishment_establishment_tracking_url(Establishment.last)
    assert_equal 'Établissement créé avec succès.', flash[:notice]
  end
end