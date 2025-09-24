require "test_helper"

class EstablishmentTrackingsControllerCreateTest < ActionDispatch::IntegrationTest # rubocop:disable Metrics/ClassLength
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:user_crp_paris)
    @establishment = establishments(:establishment_paris_no_trackings)
    sign_in @user
  end

  test "should create establishment_tracking with all required fields" do
    assert_difference("EstablishmentTracking.count") do
      post establishment_establishment_trackings_url(@establishment), params: {
        establishment_tracking: {
          state: "in_progress",
          start_date: Time.zone.today,
          referent_ids: [@user.id],
          tracking_label_ids: [],
          user_action_ids: [],
          sector_ids: [],
          participant_ids: [],
          difficulty_ids: [],
          codefi_redirect_ids: [],
          supporting_service_ids: []
        }
      }
    end

    tracking = EstablishmentTracking.last

    assert_redirected_to [@establishment, tracking]

    assert_equal "L'accompagnement a été créé avec succès.", flash[:success]
  end

  test "should not create establishment_tracking without referents" do
    assert_no_difference("EstablishmentTracking.count") do
      post establishment_establishment_trackings_url(@establishment), params: {
        establishment_tracking: {
          state: "in_progress",
          start_date: Time.zone.today,
          referent_ids: [],
          tracking_label_ids: [],
          user_action_ids: [],
          sector_ids: [],
          participant_ids: [],
          difficulty_ids: [],
          codefi_redirect_ids: [],
          supporting_service_ids: []
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should not create establishment_tracking if another active tracking exists" do
    @establishment.establishment_trackings.create!(
      state: "in_progress",
      creator: @user,
      referents: [@user]
    )

    assert_no_difference("EstablishmentTracking.count") do
      post establishment_establishment_trackings_url(@establishment), params: {
        establishment_tracking: {
          state: "in_progress",
          start_date: Time.zone.today,
          referent_ids: [@user.id],
          tracking_label_ids: [],
          user_action_ids: [],
          sector_ids: [],
          participant_ids: [],
          difficulty_ids: [],
          codefi_redirect_ids: [],
          supporting_service_ids: []
        }
      }
    end

    assert_response :redirect
  end

  test "should create establishment_tracking with all optional fields" do # rubocop:disable Metrics/BlockLength
    criticality = criticalities(:niveau_orange)
    sector = sectors(:industry)
    difficulty = difficulties(:financial)
    user_action = user_actions(:first_contact)
    codefi_redirect = codefi_redirects(:cci_cma)
    supporting_service = supporting_services(:urssaf)

    assert_difference("EstablishmentTracking.count") do
      post establishment_establishment_trackings_url(@establishment), params: {
        establishment_tracking: {
          state: "in_progress",
          start_date: Time.zone.today,
          referent_ids: [@user.id],
          criticality_id: criticality.id,
          tracking_label_ids: [],
          user_action_ids: [user_action.id],
          sector_ids: [sector.id],
          participant_ids: [],
          difficulty_ids: [difficulty.id],
          codefi_redirect_ids: [codefi_redirect.id],
          supporting_service_ids: [supporting_service.id]
        }
      }
    end

    tracking = EstablishmentTracking.last

    assert_redirected_to [@establishment, tracking]
    assert_equal "L'accompagnement a été créé avec succès.", flash[:success]

    assert_equal criticality.id, tracking.criticality_id
    assert_includes tracking.sector_ids, sector.id
    assert_includes tracking.difficulty_ids, difficulty.id
    assert_includes tracking.user_action_ids, user_action.id
    assert_includes tracking.codefi_redirect_ids, codefi_redirect.id
    assert_includes tracking.supporting_service_ids, supporting_service.id
  end
end
