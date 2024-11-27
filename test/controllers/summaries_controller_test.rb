require 'test_helper'

class SummariesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @establishment_tracking = establishment_trackings(:establishment_tracking_paris)
    @establishment = @establishment_tracking.establishment
    @summary = summaries(:summary_paris_crp)

    @user_a = users(:user_crp_paris)
    @user_b = users(:user_crp_paris_2)
  end

  test "user A sees tabs for CODEFI and CRP networks" do
    sign_in @user_a

    get establishment_establishment_tracking_path(@establishment, @establishment_tracking)

    assert_select "button", text: "Informations", count: 1
    assert_select "button", text: "CODEFI", count: 1
    assert_select "button", text: "CRP", count: 1

    # The user should only see three tabs (one for establishment details, his/her network and one for the CODEFI network)
    assert_select "button.fr-tabs__tab", count: 3
  end

  test "user A can lock and edit the summary" do
    sign_in @user_a

    get edit_establishment_establishment_tracking_summary_path(@establishment, @establishment_tracking, @summary), as: :turbo_stream

    @summary.reload
    assert_equal @user_a.id, @summary.locked_by
    assert @summary.locked?

    assert_includes @response.body, @summary.content
  end

  test "user B cannot edit a summary locked by user A" do
    sign_in @user_a

    get edit_establishment_establishment_tracking_summary_path(@establishment, @establishment_tracking, @summary)

    sign_out @user_a
    sign_in @user_b

    get establishment_establishment_tracking_path(@establishment, @establishment_tracking)

    assert_select "button[disabled]", text: "En cours d'édition par #{@user_a.email}"
  end

  test "user A unlocks the summary and user B can edit it" do
      sign_in @user_a
      get edit_establishment_establishment_tracking_summary_path(@establishment, @establishment_tracking, @summary), as: :turbo_stream

      @summary.reload
      assert_equal @user_a.id, @summary.locked_by
      assert @summary.locked?

      get cancel_establishment_establishment_tracking_summary_path(@establishment, @establishment_tracking, @summary), as: :turbo_stream

      @summary.reload
      assert_nil @summary.locked_by
      assert_not @summary.locked?

      sign_in @user_b
      get edit_establishment_establishment_tracking_summary_path(@establishment, @establishment_tracking, @summary), as: :turbo_stream

      assert_includes @response.body, @summary.content
  end
end