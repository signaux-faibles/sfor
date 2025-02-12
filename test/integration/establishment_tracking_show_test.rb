require "test_helper"

class EstablishmentTrackingShowTest < ActionDispatch::IntegrationTest
  setup do
    @establishment_tracking = establishment_trackings(:establishment_tracking_paris_no_content)

    @referent_user = users(:user_crp_paris)
    @participant_user = users(:user_crp_paris_2)

    @establishment_tracking.referents << @referent_user
    @establishment_tracking.participants << @participant_user

    @general_user = users(:user_crp_paris_3)
  end

  test "referent user sees all buttons and forms" do
    login_user(@referent_user)

    get establishment_establishment_tracking_path(@establishment_tracking.establishment, @establishment_tracking)

    assert_select "form[action*='/summaries']" do |forms|
      assert_equal 2, forms.size

      forms.each do |form|
        hidden_field = form.css("input[type=hidden][name='summary[network_id]']")
        assert hidden_field.present?, "Each form should have a hidden field for network_id"
        network_id = hidden_field.attr("value").to_s
        network = Network.find(network_id)
        assert_includes ["CRP", "CODEFI"], network.name, "The network_id should correspond to CODEFI or CRP"
      end
    end

    assert_select "form[action*='/comments']" do |forms|
      assert_equal 2, forms.size

      forms.each do |form|
        hidden_field = form.css("input[type=hidden][name='comment[network_id]']")
        assert hidden_field.present?, "Each form should have a hidden field for network_id"
        network_id = hidden_field.attr("value").to_s
        network = Network.find(network_id)
        assert_includes ["CRP", "CODEFI"], network.name, "The network_id should correspond to CODEFI or CRP"
      end
    end

    assert_select "a", text: "Modifier les informations", count: 1
    assert_select "a", text: "Gérer les contributeurs", count: 1
  end

  test "participant user sees all buttons and forms but cannot edit state" do
    login_user(@participant_user)

    get edit_establishment_establishment_tracking_path(@establishment_tracking.establishment, @establishment_tracking)

    # Check that "Statut" dropdown is not present
    assert_select "select[name=?]", "establishment_tracking[state]", count: 0

    get establishment_establishment_tracking_path(@establishment_tracking.establishment, @establishment_tracking)

    assert_select "form[action*='/summaries']" do |forms|
      assert_equal 2, forms.size

      forms.each do |form|
        hidden_field = form.css("input[type=hidden][name='summary[network_id]']")
        assert hidden_field.present?, "Each form should have a hidden field for network_id"
        network_id = hidden_field.attr("value").to_s
        network = Network.find(network_id)
        assert_includes ["CRP", "CODEFI"], network.name, "The network_id should correspond to CODEFI or CRP"
      end
    end

    assert_select "a", text: "Modifier les informations", count: 1
    assert_select "a", text: "Gérer les contributeurs", count: 1
  end

  test "general user can only see button to handle referents and participants" do
    login_user(@general_user)

    get establishment_establishment_tracking_path(@establishment_tracking.establishment, @establishment_tracking)

    assert_select "form[action*='/summaries']", count: 0
    assert_select "form[action*='/comments']", count: 0
    assert_select "a", text: "Modifier les informations", count: 0
    assert_select "a", text: "Gérer les contributeurs", count: 1
  end

  test "unauthorized users are redirected with an alert in HTML format" do
    login_user(@general_user)

    get edit_establishment_establishment_tracking_path(@establishment_tracking.establishment, @establishment_tracking)

    assert_response :redirect
    follow_redirect!

    assert_select ".fr-alert", text: "Vous n'êtes pas autorisé à effectuer cette action."
  end
end