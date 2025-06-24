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
end
