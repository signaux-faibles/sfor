require "test_helper"

class SummariesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @establishment_tracking = establishment_trackings(:establishment_tracking_paris)
    @establishment = @establishment_tracking.establishment
    @summary = summaries(:summary_paris_crp)

    @user_a = users(:user_crp_paris)
    @user_b = users(:user_crp_paris2)

    @establishment_tracking.referents << [@user_a, @user_b]
  end

  test "user A sees tabs CRP and CODEFI networks" do
    # Ensure networks are active
    networks(:network_crp).update!(active: true)
    networks(:network_codefi).update!(active: true)

    sign_in @user_a

    get establishment_establishment_tracking_path(@establishment, @establishment_tracking)

    # Check that we have exactly 3 tabs
    assert_select "button.fr-tabs__tab", count: 3

    # Check that we have the Informations tab
    assert_select "button.fr-tabs__tab", text: "Informations", count: 1

    # Check that we have both network tabs with their specific names
    assert_select "button.fr-tabs__tab[id='tabpanel-crp']" do |element|
      assert_match(/^CRP\s*$/, element.text.strip)
    end
    assert_select "button.fr-tabs__tab[id='tabpanel-codefi']" do |element|
      assert_match(/^CODEFI\s*$/, element.text.strip)
    end
  end

  test "user A can lock and edit the summary" do
    sign_in @user_a

    get edit_establishment_establishment_tracking_summary_path(@establishment, @establishment_tracking, @summary),
        as: :turbo_stream

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
    get edit_establishment_establishment_tracking_summary_path(@establishment, @establishment_tracking, @summary),
        as: :turbo_stream

    @summary.reload
    assert_equal @user_a.id, @summary.locked_by
    assert @summary.locked?

    get cancel_establishment_establishment_tracking_summary_path(@establishment, @establishment_tracking, @summary),
        as: :turbo_stream

    @summary.reload
    assert_nil @summary.locked_by
    assert_not @summary.locked?

    sign_in @user_b
    get edit_establishment_establishment_tracking_summary_path(@establishment, @establishment_tracking, @summary),
        as: :turbo_stream

    assert_includes @response.body, @summary.content
  end
end
