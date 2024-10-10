class EstablishmentTrackingsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @establishment_tracking_paris = establishment_trackings(:establishment_tracking_paris)
    @establishment_tracking_finistere = establishment_trackings(:establishment_tracking_finistere)

    sign_in users(:user_crp_paris)
  end

  test "should get index" do
    get establishment_trackings_url
    assert_response :success
    assert_includes response.body, @establishment_tracking_paris.establishment.raison_sociale
    assert_not_includes response.body, @establishment_tracking_finistere.establishment.raison_sociale
  end
end