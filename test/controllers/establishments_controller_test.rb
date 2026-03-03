# frozen_string_literal: true

require "test_helper"

class EstablishmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:user_crp_paris)
    @establishment_paris = establishments(:establishment_paris)
    @establishment_finistere = establishments(:establishment_finistere)
    @establishment_no_siege = establishments(:establishment_no_siege)
  end

  test "show redirects to sign in when not authenticated" do
    get establishment_path(@establishment_paris.siret)

    assert_redirected_to new_user_session_path
  end

  test "show returns success when authenticated and establishment exists" do
    sign_in @user

    get establishment_path(@establishment_paris.siret)

    assert_response :success
  end

  test "show displays establishment raison_sociale (from company)" do
    sign_in @user

    get establishment_path(@establishment_paris.siret)

    assert_response :success
    # Establishment#raison_sociale delegates to company
    assert_includes @response.body, @establishment_paris.raison_sociale
  end

  test "show displays establishment siret in page" do
    sign_in @user

    get establishment_path(@establishment_paris.siret)

    assert_response :success
    assert_includes @response.body, @establishment_paris.siret
  end

  test "show returns not found when establishment does not exist" do
    sign_in @user

    get establishment_path("00000000000000")

    assert_response :not_found
  end

  test "establishment_trackings_list_widget returns success" do
    sign_in @user

    get establishment_trackings_list_widget_establishment_path(@establishment_paris.siret),
        headers: { "Accept" => "text/html" }

    assert_response :success
  end

  test "establishment_trackings_list_widget shows out of zone message when user has no geo access" do
    user_finistere = users(:user_crp_finistere)
    sign_in user_finistere

    get establishment_trackings_list_widget_establishment_path(@establishment_paris.siret),
        headers: { "Accept" => "text/html" }

    assert_response :success
    assert_includes @response.body,
                    "Vos accès géographiques ne vous permettent pas d'accéder aux accompagnements de cet établissement."
  end

  test "data_urssaf_widget shows empty state when no data" do
    sign_in @user

    travel_to Date.new(2025, 2, 15) do
      get data_urssaf_widget_establishment_path(@establishment_no_siege.siret),
          headers: { "Accept" => "text/html" }
    end

    assert_response :success
    assert_includes @response.body, "Aucune donnée disponible pour cette entreprise."
  end

  test "data_effectif_ap_widget shows empty state when no data" do
    sign_in @user

    travel_to Date.new(2025, 2, 15) do
      get data_effectif_ap_widget_establishment_path(@establishment_no_siege.siret),
          headers: { "Accept" => "text/html" }
    end

    assert_response :success
    assert_includes @response.body, "Aucune donnée disponible pour cette entreprise."
  end

  test "data_urssaf_widget renders chart data attributes" do
    sign_in @user

    travel_to Date.new(2025, 2, 15) do
      get data_urssaf_widget_establishment_path(@establishment_paris.siret), headers: { "Accept" => "text/html" }
    end

    assert_response :success
    assert_includes @response.body, "Cotisations, impayés et délais de paiement URSSAF"
    assert_includes @response.body, "data-orthogonal-chart-widget-dataset-names-value="
    assert_includes @response.body, "Cotisations appelées"
    assert_includes @response.body, "Dette restante (part salariale)"
    assert_includes @response.body, "Dette restante (part patronale)"
    assert_includes @response.body, "Montant de l&#39;échéancier du délai de paiement"
    assert_includes @response.body, "1201"
    assert_includes @response.body, "1001"
    assert_includes @response.body, "2000"
    assert_includes @response.body, "5000"
  end

  test "data_effectif_ap_widget renders chart data attributes" do
    sign_in @user

    travel_to Date.new(2025, 2, 15) do
      get data_effectif_ap_widget_establishment_path(@establishment_paris.siret),
          headers: { "Accept" => "text/html" }
    end

    assert_response :success
    assert_includes @response.body, "Effectifs / Activité partielle"
    assert_includes @response.body, "data-orthogonal-chart-widget-dataset-names-value="
    assert_includes @response.body, "Effectifs (salariés)"
    assert_includes @response.body, "Consommation d&#39;activité partielle (ETP)"
    assert_includes @response.body, "Autorisation d&#39;activité partielle (ETP)"
    assert_includes @response.body, "42"
    assert_includes @response.body, "10"
    assert_includes @response.body, "13"
  end
end
