require "test_helper"

class EstablishmentTrackingsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    setup_test_data
    sign_in @user_crp_paris
  end

  private

  def setup_test_data
    setup_tracking_data
    setup_user_data
  end

  def setup_tracking_data
    @establishment_tracking_paris = establishment_trackings(:establishment_tracking_paris)
    @establishment_tracking_paris2 = establishment_trackings(:establishment_tracking_paris2)
    @establishment_tracking_paris3 = establishment_trackings(:establishment_tracking_paris3)
    @establishment_tracking_finistere = establishment_trackings(:establishment_tracking_finistere)
    @establishment_tracking_paris_with_urssaf_referents =
      establishment_trackings(:establishment_tracking_paris_with_urssaf_referents)
    @establishment_tracking_paris_no_content = establishment_trackings(:establishment_tracking_paris_no_content)
  end

  def setup_user_data
    @establishment_paris = establishments(:establishment_paris)
    @establishment_paris2 = establishments(:establishment_paris2)
    @user_crp_paris = users(:user_crp_paris)
    @user_urssaf_paris = users(:user_urssaf_paris)
    @user_crp_paris2 = users(:user_crp_paris2)
  end

  def assert_tracking_included(tracking)
    assert_includes response.body, tracking.establishment.raison_sociale
  end

  def assert_tracking_not_included(tracking)
    assert_not_includes response.body, tracking.establishment.raison_sociale
  end
end

class EstablishmentTrackingsIndexTest < EstablishmentTrackingsControllerTest
  test "should get index" do
    get establishment_trackings_url
    assert_response :success
    assert_tracking_included(@establishment_tracking_paris)
    assert_tracking_not_included(@establishment_tracking_finistere)
  end

  test "should show trackings where user is referent when my_tracking=1" do
    get establishment_trackings_url, params: { q: { my_tracking: "1" } }
    assert_response :success
    assert_tracking_included(@establishment_tracking_paris)
    assert_tracking_not_included(@establishment_tracking_paris_with_urssaf_referents)
    assert_tracking_not_included(@establishment_tracking_finistere)
  end

  test "should show trackings where user is participant when my_tracking=1" do
    @establishment_tracking_paris_with_urssaf_referents.participants << @user_crp_paris
    get establishment_trackings_url, params: { q: { my_tracking: "1" } }
    assert_response :success
    assert_tracking_included(@establishment_tracking_paris_with_urssaf_referents)
  end

  test "should show trackings from user's networks when my_tracking=network" do
    get establishment_trackings_url, params: { q: { my_tracking: "network" } }
    assert_response :success
    assert_tracking_included(@establishment_tracking_paris)
    assert_tracking_not_included(@establishment_tracking_finistere)
  end

  test "should show trackings where referents share the same network when my_tracking=network" do
    get establishment_trackings_url, params: { q: { my_tracking: "network" } }
    assert_response :success
    assert_tracking_included(@establishment_tracking_paris2)
  end
end

class EstablishmentTrackingsCrudTest < EstablishmentTrackingsControllerTest # rubocop:disable Metrics/ClassLength
  test "should get show" do
    get establishment_establishment_tracking_url(@establishment_paris, @establishment_tracking_paris)
    assert_response :success
    assert_tracking_included(@establishment_tracking_paris)
  end

  test "should get new" do
    get new_establishment_establishment_tracking_url(@establishment_paris)
    assert_response :success
  end

  test "should create establishment_tracking" do
    assert_difference("EstablishmentTracking.count") do
      post establishment_establishment_trackings_url(@establishment_paris2), params: {
        establishment_tracking: {
          state: "in_progress",
          start_date: Time.zone.today,
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

    tracking = EstablishmentTracking.last

    assert_redirected_to [@establishment_paris2, tracking]
    assert_equal "L'accompagnement a été créé avec succès.", flash[:success]
  end

  test "should not create establishment_tracking with invalid params" do
    assert_no_difference("EstablishmentTracking.count") do
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

  test "should update establishment_tracking and redirect to confirm if completed" do
    patch establishment_establishment_tracking_url(@establishment_paris, @establishment_tracking_paris), params: {
      establishment_tracking: {
        state: "completed",
        tracking_label_ids: [],
        user_action_ids: [],
        sector_ids: [],
        participant_ids: [],
        referent_ids: [@user_crp_paris.id],
        difficulty_ids: [],
        codefi_redirect_ids: []
      }
    }

    assert_redirected_to confirm_establishment_establishment_tracking_path(
      @establishment_paris,
      @establishment_tracking_paris
    )
  end

  test "should update establishment_tracking with all optional fields" do # rubocop:disable Metrics/BlockLength
    criticality = criticalities(:niveau_orange)
    size = sizes(:small)
    sector = sectors(:industry)
    difficulty = difficulties(:financial)
    user_action = user_actions(:first_contact)
    codefi_redirect = codefi_redirects(:cci_cma)
    supporting_service = supporting_services(:urssaf)

    patch establishment_establishment_tracking_url(@establishment_paris, @establishment_tracking_paris), params: {
      establishment_tracking: {
        state: "in_progress",
        start_date: Time.zone.today,
        referent_ids: [@user_crp_paris.id],
        criticality_id: criticality.id,
        size_id: size.id,
        tracking_label_ids: [],
        user_action_ids: [user_action.id],
        sector_ids: [sector.id],
        participant_ids: [],
        difficulty_ids: [difficulty.id],
        codefi_redirect_ids: [codefi_redirect.id],
        supporting_service_ids: [supporting_service.id]
      }
    }

    assert_redirected_to establishment_establishment_tracking_url(@establishment_paris, @establishment_tracking_paris)
    assert_equal "L'accompagnement a été mis à jour avec succès.", flash[:success]

    @establishment_tracking_paris.reload
    assert_equal criticality.id, @establishment_tracking_paris.criticality_id
    assert_equal size.id, @establishment_tracking_paris.size_id
    assert_includes @establishment_tracking_paris.sector_ids, sector.id
    assert_includes @establishment_tracking_paris.difficulty_ids, difficulty.id
    assert_includes @establishment_tracking_paris.user_action_ids, user_action.id
    assert_includes @establishment_tracking_paris.codefi_redirect_ids, codefi_redirect.id
    assert_includes @establishment_tracking_paris.supporting_service_ids, supporting_service.id
  end

  test "should destroy establishment_tracking" do
    assert_difference("EstablishmentTracking.count", -1) do
      delete establishment_establishment_tracking_url(@establishment_paris, @establishment_tracking_paris)
    end

    assert_redirected_to @establishment_paris
    assert_equal "L'accompagnement a été supprimé avec succès.", flash[:success]
  end
end

class EstablishmentTrackingsContributorsTest < EstablishmentTrackingsControllerTest
  test "should get manage_contributors" do
    get manage_contributors_establishment_establishment_tracking_url(@establishment_paris,
                                                                     @establishment_tracking_paris)
    assert_response :success
  end

  test "should update contributors" do
    patch update_contributors_establishment_establishment_tracking_url(
      @establishment_paris,
      @establishment_tracking_paris
    ), params: {
      establishment_tracking: {
        referent_ids: [@user_crp_paris.id],
        participant_ids: []
      }
    }

    assert_redirected_to establishment_establishment_tracking_url(@establishment_paris, @establishment_tracking_paris)
    assert_equal "Contributeurs de l'accompagnement mis à jour avec succès.", flash[:success]
  end
end

class EstablishmentTrackingsSiretTest < EstablishmentTrackingsControllerTest
  test "should handle new_by_siret with existing establishment" do
    get new_establishment_tracking_by_siret_url, params: {
      siret: @establishment_paris.siret,
      code_departement: @establishment_paris.department.code
    }

    assert_redirected_to establishment_establishment_tracking_url(@establishment_paris, @establishment_tracking_paris)
  end

  test "should handle new_by_siret with non-existing establishment" do
    assert_difference("Establishment.count") do
      get new_establishment_tracking_by_siret_url, params: {
        siret: "12345678901234",
        denomination: "New Company",
        code_departement: @establishment_paris.department.code
      }
    end

    assert_redirected_to new_establishment_establishment_tracking_url(Establishment.last)
  end
end
