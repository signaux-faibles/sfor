require 'test_helper'
class EstablishmentTrackingsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @establishment_tracking_paris = establishment_trackings(:establishment_tracking_paris)
    @establishment_tracking_finistere = establishment_trackings(:establishment_tracking_finistere)
    @establishment_tracking_paris_with_urssaf_referents = establishment_trackings(:establishment_tracking_paris_with_urssaf_referents)

    sign_in users(:user_crp_paris)
  end

  test "should get index" do
    get establishment_trackings_url
    assert_response :success
    assert_includes response.body, @establishment_tracking_paris.establishment.raison_sociale
    assert_not_includes response.body, @establishment_tracking_finistere.establishment.raison_sociale
  end

  test "should only include establishment_trackings within user's networks when my network filter is used" do
    params = {
      q: {
        my_tracking: "network",
      },
    }
    get establishment_trackings_url, params: params

    assert_response :success

    assert_includes response.body, @establishment_tracking_paris.establishment.raison_sociale
    assert_not_includes response.body, @establishment_tracking_finistere.establishment.raison_sociale
    assert_not_includes response.body, @establishment_tracking_paris_with_urssaf_referents.establishment.raison_sociale
  end
end