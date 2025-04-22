require "test_helper"

class EstablishmentTrackingEditTest < ActionDispatch::IntegrationTest
  setup do
    @establishment_tracking = establishment_trackings(:establishment_tracking_paris_no_content)
    @referent_user = users(:user_crp_paris)
    @codefi_redirect = codefi_redirects(:cci_cma)

    @establishment_tracking.referents << @referent_user
    login_user(@referent_user)

    @redirect_action_name = "Réorientation externe au codéfi"
  end

  test "editing an establishment_tracking with a CodefiRedirect automatically adds the correct UserAction" do
    assert_not @establishment_tracking.user_actions.exists?(name: @redirect_action_name)

    patch establishment_establishment_tracking_path(
      @establishment_tracking.establishment,
      @establishment_tracking
    ), params: {
      establishment_tracking: {
        codefi_redirect_ids: [@codefi_redirect.id],
        tracking_label_ids: [],
        state: @establishment_tracking.state
      }
    }

    assert_response :redirect
    follow_redirect!

    @establishment_tracking.reload

    assert_includes @establishment_tracking.codefi_redirect_ids, @codefi_redirect.id

    assert @establishment_tracking.user_actions.exists?(name: @redirect_action_name),
           "Expected the UserAction '#{@redirect_action_name}' to be added"
  end
end
