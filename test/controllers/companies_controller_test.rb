# frozen_string_literal: true

require "test_helper"
require "minitest/mock"

class CompaniesControllerTest < ActionDispatch::IntegrationTest # rubocop:disable Metrics/ClassLength
  setup do
    @user = users(:user_crp_paris)
    @company_paris = companies(:company_paris)
    @company_finistere = companies(:company_finistere)
    @company_no_siege = companies(:company_no_siege)
  end

  test "show redirects to sign in when not authenticated" do
    get company_path(@company_paris.siren)

    assert_redirected_to new_user_session_path
  end

  test "show returns success when authenticated and company exists" do
    sign_in @user

    get company_path(@company_paris.siren)

    assert_response :success
  end

  test "show displays company raison_sociale" do
    sign_in @user

    get company_path(@company_paris.siren)

    assert_response :success
    assert_includes @response.body, @company_paris.raison_sociale
  end

  test "show displays company siren in page" do
    sign_in @user

    get company_path(@company_paris.siren)

    assert_response :success
    assert_includes @response.body, @company_paris.siren
  end

  test "show redirects when company does not exist" do
    sign_in @user

    get company_path("000000000")

    assert_redirected_to home_path
    assert_equal "Cette fiche entreprise n'existe pas dans SignauxFaibles", flash[:alert]
  end

  test "detection_widget returns success when company has score entry" do
    sign_in @user

    get detection_widget_company_path(@company_paris.siren), headers: { "Accept" => "text/html" }

    assert_response :success
  end

  test "establishments_widget returns success" do
    sign_in @user

    get establishments_widget_company_path(@company_paris.siren), headers: { "Accept" => "text/html" }

    assert_response :success
  end

  test "establishments_widget renders labels and data for enriched establishments" do
    sign_in @user

    closed_date = Time.zone.local(2025, 2, 1).to_i
    insee_responses = {
      "12345678900001" => { "data" => { "etat_administratif" => "A" } },
      "12345678900010" => { "data" => { "etat_administratif" => "F", "date_fermeture" => closed_date } }
    }
    fake_service = Struct.new(:responses) do
      def fetch_establishment_by_siret(siret)
        responses[siret]
      end
    end.new(insee_responses)

    Api::InseeApiService.stub(:new, fake_service) do
      get establishments_widget_company_path(@company_paris.siren), headers: { "Accept" => "text/html" }
    end

    assert_response :success
    assert_includes @response.body, "Cette structure possède 8 établissements dont 3 sont en activité."
    assert_includes @response.body, "Siège social"
    assert_includes @response.body, "42"
    assert_includes @response.body, "12345678900010"
    assert_not_includes @response.body, "99"
    assert_includes @response.body, "Oui"
    assert_includes @response.body, "Non"
    assert_includes @response.body, "En activité"
    assert_includes @response.body, "Fermé le 01/02/2025"
  end

  test "history_detection_widget shows history button when current list has no alert but past alert exists" do
    sign_in @user

    List.create!(
      label: "Liste test 2026",
      code: "LIST_TEST_2026",
      list_date: Date.new(2026, 1, 15),
      sjcf_filter_active: false
    )
    company_score_entries(:one_paris_list_test_2024).update!(alert: "Alerte seuil F2")

    get history_detection_widget_company_path(@company_paris.siren), headers: { "Accept" => "text/html" }

    assert_response :success
    assert_includes @response.body, "Historique des alertes"
    assert_includes @response.body, "Liste test 2024"
    assert_includes @response.body, "sf-moderated-alert"
    assert_includes @response.body, "sf-no-alert"
  end

  test "feedback_detection_widget creates useful rating" do
    sign_in @user

    list = lists(:list_test_2025)

    assert_difference("CompanyListRating.count", 1) do
      post feedback_detection_widget_company_path(@company_paris.siren),
           params: { useful: "true", precisions: "RAS" },
           headers: { "Accept" => "text/html" }
    end

    rating = CompanyListRating.find_by!(siren: @company_paris.siren,
                                        list_name: list.label,
                                        user_email: @user.email)
    assert_equal true, rating.useful
    assert_response :success
  end

  test "feedback_detection_widget blocks non-useful rating without reasons" do
    sign_in @user

    assert_no_difference("CompanyListRating.count") do
      post feedback_detection_widget_company_path(@company_paris.siren),
           params: { useful: "false" },
           headers: { "Accept" => "text/html" }
    end

    assert_response :unprocessable_entity
    assert_includes @response.body, "Vous devez cocher au moins une raison."
  end

  test "feedback_detection_widget creates non-useful rating with reasons" do
    sign_in @user

    reason = RatingReason.create!(code: "R1", libelle: "Raison 1")

    assert_difference("CompanyListRating.count", 1) do
      assert_difference("RatingReasonsRating.count", 1) do
        post feedback_detection_widget_company_path(@company_paris.siren),
             params: { useful: "false", raisons: [reason.code], precisions: "Commentaire" },
             headers: { "Accept" => "text/html" }
      end
    end

    rating = CompanyListRating.find_by!(siren: @company_paris.siren, user_email: @user.email)
    assert_equal false, rating.useful
    assert_response :success
  end

  test "feedback_detection_widget blocks duplicate rating" do
    sign_in @user

    list = lists(:list_test_2025)
    CompanyListRating.create!(
      siren: @company_paris.siren,
      list_name: list.label,
      user_email: @user.email,
      user_segment: @user.segment.name,
      useful: true,
      comment: "Premier avis"
    )

    assert_no_difference("CompanyListRating.count") do
      post feedback_detection_widget_company_path(@company_paris.siren),
           params: { useful: "true" },
           headers: { "Accept" => "text/html" }
    end

    assert_response :unprocessable_entity
  end

  test "data_urssaf_widget renders chart data attributes" do
    sign_in @user

    travel_to Date.new(2025, 2, 15) do
      get data_urssaf_widget_company_path(@company_paris.siren), headers: { "Accept" => "text/html" }
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
      get data_effectif_ap_widget_company_path(@company_paris.siren), headers: { "Accept" => "text/html" }
    end

    assert_response :success
    assert_includes @response.body, "Effectifs / Activité partielle"
    assert_includes @response.body, "data-orthogonal-chart-widget-dataset-names-value="
    assert_includes @response.body, "Effectifs (salariés)"
    assert_includes @response.body, "Consommation d&#39;activité partielle (ETP)"
    assert_includes @response.body, "Autorisation d&#39;activité partielle (ETP)"
    assert_includes @response.body, "50"
    assert_includes @response.body, "10"
    assert_includes @response.body, "13"
  end

  test "show displays Accompagnements tab" do
    sign_in @user

    get company_path(@company_paris.siren)

    assert_response :success
    assert_includes @response.body, "Accompagnements"
  end

  test "establishment_trackings_list_widget returns success" do
    sign_in @user

    get establishment_trackings_list_widget_company_path(@company_paris.siren),
        headers: { "Accept" => "text/html" }

    assert_response :success
  end

  test "establishment_trackings_list_widget redirects to sign in when not authenticated" do
    get establishment_trackings_list_widget_company_path(@company_paris.siren),
        headers: { "Accept" => "text/html" }

    assert_redirected_to new_user_session_path
  end

  test "establishment_trackings_list_widget shows never had any tracking message when company has no trackings" do
    sign_in @user

    # Company Paris has trackings in fixtures; remove them so we get the "no trackings" scenario
    EstablishmentTracking.where(establishment: @company_paris.establishments).destroy_all

    get establishment_trackings_list_widget_company_path(@company_paris.siren),
        headers: { "Accept" => "text/html" }

    assert_response :success
    assert_includes @response.body, "L'entreprise n'a jamais fait l'objet d'un accompagnement."
    assert_includes @response.body, "Rappel : les accompagnements sont créés au niveau des fiches établissements."
    assert_includes @response.body, "Liste des établissements"
    assert_includes @response.body, company_path(@company_paris)
  end

  test "establishment_trackings_list_widget shows siege link when company has no trackings but has siege" do
    sign_in @user

    EstablishmentTracking.where(establishment: @company_paris.establishments).destroy_all
    siege = @company_paris.establishments.find_by(siege: true)
    assert siege.present?, "company_paris should have a siege establishment in fixtures"

    get establishment_trackings_list_widget_company_path(@company_paris.siren),
        headers: { "Accept" => "text/html" }

    assert_response :success
    assert_includes @response.body, "établissement siège"
    assert_includes @response.body, establishment_path(siege)
  end

  test "establishment_trackings_list_widget when company has no trackings and no siege shows company link only" do
    sign_in @user

    # company_no_siege has one establishment with siege: false and no trackings
    get establishment_trackings_list_widget_company_path(@company_no_siege.siren),
        headers: { "Accept" => "text/html" }

    assert_response :success
    assert_includes @response.body, "L'entreprise n'a jamais fait l'objet d'un accompagnement."
    assert_includes @response.body, company_path(@company_no_siege)
    assert_includes @response.body, "Liste des établissements"
    # No siege link when company has no siege establishment
    assert_not_includes @response.body, "établissement siège"
  end

  test "establishment_trackings_list_widget shows out of zone message when user has no geo access and is not referent or participant" do
    user_finistere = users(:user_crp_finistere)
    sign_in user_finistere

    # User from Finistere views company Paris (Paris department) - no establishment in their departments
    # and they are not referent/participant on any Paris company tracking
    get establishment_trackings_list_widget_company_path(@company_paris.siren),
        headers: { "Accept" => "text/html" }

    assert_response :success
    assert_includes @response.body,
                    "Vos accès géographiques ne vous permettent pas d'accéder aux accompagnements de cette entreprise."
  end

  test "establishment_trackings_list_widget shows active trackings when user has department access" do
    sign_in @user

    get establishment_trackings_list_widget_company_path(@company_paris.siren),
        headers: { "Accept" => "text/html" }

    assert_response :success
    assert_includes @response.body, "Accompagnement en cours de l'entreprise"
  end

  test "establishment_trackings_list_widget shows both active and history when company has active and completed trackings" do
    sign_in @user

    # Fixtures: company_paris has in_progress, under_surveillance and establishment_tracking_paris_completed
    get establishment_trackings_list_widget_company_path(@company_paris.siren),
        headers: { "Accept" => "text/html" }

    assert_response :success
    assert_includes @response.body, "Accompagnement en cours de l'entreprise"
    assert_includes @response.body, "Historique des accompagnements de l'entreprise"
  end

  test "establishment_trackings_list_widget shows under_surveillance in active section" do
    sign_in @user

    get establishment_trackings_list_widget_company_path(@company_paris.siren),
        headers: { "Accept" => "text/html" }

    assert_response :success
    # establishment_tracking_paris_under_surveillance is on establishment 12345678900015
    assert_includes @response.body, "12345678900015"
    assert_includes @response.body, "Sous surveillance", "Active section should include under_surveillance trackings"
  end

  test "establishment_trackings_list_widget shows trackings when user is referent on company tracking but out of zone" do
    user_finistere = users(:user_crp_finistere)
    tracking_paris = establishment_trackings(:establishment_tracking_paris)

    # Add Finistere user as referent on a Paris company tracking (so they can see via referent, not geo)
    TrackingReferent.create!(establishment_tracking: tracking_paris, user: user_finistere)

    sign_in user_finistere

    get establishment_trackings_list_widget_company_path(@company_paris.siren),
        headers: { "Accept" => "text/html" }

    assert_response :success
    assert_includes @response.body, "Accompagnement en cours de l'entreprise"
  end

  test "establishment_trackings_list_widget shows trackings when user is participant on company tracking but out of zone" do
    user_finistere = users(:user_crp_finistere)
    # establishment_tracking_paris3 has participant user_crp_paris3 (Paris). Add user_finistere as participant.
    tracking = establishment_trackings(:establishment_tracking_paris3)
    TrackingParticipant.create!(establishment_tracking: tracking, user: user_finistere)

    sign_in user_finistere

    get establishment_trackings_list_widget_company_path(@company_paris.siren),
        headers: { "Accept" => "text/html" }

    assert_response :success
    assert_includes @response.body, "Accompagnement en cours de l'entreprise"
  end

  test "establishment_trackings_list_widget shows no active message and history when only completed trackings" do
    sign_in @user

    # Set all company_paris trackings to completed so there are no active ones
    EstablishmentTracking.where(establishment: @company_paris.establishments).update_all(state: "completed")

    get establishment_trackings_list_widget_company_path(@company_paris.siren),
        headers: { "Accept" => "text/html" }

    assert_response :success
    assert_includes @response.body,
                    "L'entreprise n'a pas d'accompagnement en cours ou sous-surveillance."
    assert_includes @response.body, "Historique des accompagnements de l'entreprise"
  end
end
