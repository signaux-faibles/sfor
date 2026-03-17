# frozen_string_literal: true

require "test_helper"

class ListsControllerTest < ActionDispatch::IntegrationTest # rubocop:disable Metrics/ClassLength
  setup do
    @user = users(:user_crp_paris)
    @list_2025 = lists(:list_test_2025)
    @list_2024 = lists(:list_test_2024)
  end

  # procol_at_date is a SQL function created by migrations; it is not in schema.rb.
  # Run `rails db:drop db:create db:migrate RAILS_ENV=test` to have it in the test DB.
  def procol_at_date_available?
    @procol_at_date_available ||= ActiveRecord::Base.connection.execute(
      "SELECT 1 FROM pg_proc WHERE proname = 'procol_at_date'"
    ).any?
  end

  test "index redirects to sign in when not authenticated" do
    get lists_path

    assert_redirected_to new_user_session_path
  end

  test "index returns success when authenticated" do
    sign_in @user

    get lists_path

    assert_response :success
  end

  test "index shows page title and table" do
    sign_in @user

    get lists_path

    assert_select "h1", text: "Listes de détection"
    assert_select "table#table-lg"
    assert_select "caption", text: "Toutes les listes"
    assert_select "th", text: "Liste"
    assert_select "th", text: "Actions"
  end

  test "index lists all lists ordered by list_date desc" do
    sign_in @user

    get lists_path

    # list_test_2025 has list_date 2025-01-15, list_test_2024 has 2024-06-01, list_test_2023 has 2023-06-01
    assert_select "tbody tr", count: 3
    assert_includes @response.body, "Liste test 2025"
    assert_includes @response.body, "Liste test 2024"
    assert_includes @response.body, "Liste test 2023"
    # 2025 must appear before 2024 in the body (order list_date desc)
    assert @response.body.index("Liste test 2025") < @response.body.index("Liste test 2024"),
           "Liste test 2025 should appear before Liste test 2024"
    assert @response.body.index("Liste test 2024") < @response.body.index("Liste test 2023"),
           "Liste test 2024 should appear before Liste test 2023"
  end

  test "index shows link to each list show page" do
    sign_in @user

    get lists_path

    assert_select "a[href=?]", list_path(@list_2025)
    assert_select "a[href=?]", list_path(@list_2024)
  end

  test "index shows empty state when no lists" do
    sign_in @user
    List.delete_all

    get lists_path

    assert_select "p", text: "Aucune liste disponible"
  end

  # --- show action ---
  # user_crp_paris has department 75 only, so policy_scope shows only company_paris (123456789) for list_test_2025.

  test "show redirects to sign in when not authenticated" do
    get list_path(@list_2025), params: { search: {} }

    assert_redirected_to new_user_session_path
  end

  test "show returns success with empty search params" do
    sign_in @user

    get list_path(@list_2025), params: { search: {} }

    assert_response :success
    assert_select "h1", text: "Liste #{@list_2025.label}"
    assert_select "h2", text: "Résultats de recherche"
  end

  test "show handles missing search param via rescue" do
    sign_in @user

    # No :search key triggers ParameterMissing; rescue renders with default empty search
    get list_path(@list_2025)

    assert_response :success
    assert_select "h1", text: "Liste #{@list_2025.label}"
  end

  test "show displays companies in list for user department" do
    sign_in @user

    get list_path(@list_2025), params: { search: {} }

    # user_crp_paris sees only department 75 → company_paris
    assert_includes @response.body, "Company Paris"
    assert_includes @response.body, "123456789"
    assert_not_includes @response.body, "Aucun résultat trouvé"
  end

  test "show redirects to lists with alert when list not found" do
    sign_in @user

    get list_path(id: 999_999), params: { search: {} }

    assert_redirected_to lists_path
    assert_equal "Liste introuvable", flash[:alert]
  end

  test "show filter q narrows by SIREN" do
    sign_in @user

    get list_path(@list_2025), params: { search: { q: "123" } }

    assert_response :success
    assert_includes @response.body, "Company Paris"
    assert_includes @response.body, "123456789"
  end

  test "show filter q with no match shows empty results" do
    sign_in @user

    get list_path(@list_2025), params: { search: { q: "000000000" } }

    assert_response :success
    assert_includes @response.body, "Aucun résultat trouvé"
  end

  test "show filter q narrows by raison sociale" do
    sign_in @user

    get list_path(@list_2025), params: { search: { q: "Company Paris" } }

    assert_response :success
    assert_includes @response.body, "Company Paris"
  end

  test "show filter effectif_min includes company above threshold" do
    sign_in @user

    # company_paris has osf_ent_effectif effectif 50
    get list_path(@list_2025), params: { search: { effectif_min: 10 } }

    assert_response :success
    assert_includes @response.body, "Company Paris"
  end

  test "show filter effectif_min excludes company below threshold" do
    sign_in @user

    get list_path(@list_2025), params: { search: { effectif_min: 100 } }

    assert_response :success
    assert_includes @response.body, "Aucun résultat trouvé"
  end

  test "show filter score_min includes company above threshold" do
    sign_in @user

    # company_paris has score 75.5 in list_test_2025
    get list_path(@list_2025), params: { search: { score_min: 70 } }

    assert_response :success
    assert_includes @response.body, "Company Paris"
  end

  test "show filter dette_sociale_min includes company above threshold" do
    sign_in @user

    # company_paris osf_debit: 1000.5 + 2000 = 3000.5
    get list_path(@list_2025), params: { search: { dette_sociale_min: 2000 } }

    assert_response :success
    assert_includes @response.body, "Company Paris"
  end

  test "show filter dette_sociale_min excludes company below threshold" do
    sign_in @user

    get list_path(@list_2025), params: { search: { dette_sociale_min: 5000 } }

    assert_response :success
    assert_includes @response.body, "Aucun résultat trouvé"
  end

  test "show filter departement_in filters by department" do
    sign_in @user

    get list_path(@list_2025), params: { search: { departement_in: ["75"] } }

    assert_response :success
    assert_includes @response.body, "Company Paris"
  end

  test "show filter departement_in with other department shows no results for Paris user" do
    sign_in @user

    # user_crp_paris only has department 75; filter departement_in 29 → intersection empty
    get list_path(@list_2025), params: { search: { departement_in: ["29"] } }

    assert_response :success
    assert_includes @response.body, "Aucun résultat trouvé"
  end

  test "show filter forme_juridique includes matching company" do
    sign_in @user

    # company_paris has statut_juridique 5710
    get list_path(@list_2025), params: { search: { forme_juridique: ["5710"] } }

    assert_response :success
    assert_includes @response.body, "Company Paris"
  end

  test "show filter forme_juridique excludes non-matching company" do
    sign_in @user

    get list_path(@list_2025), params: { search: { forme_juridique: ["5499"] } }

    assert_response :success
    assert_includes @response.body, "Aucun résultat trouvé"
  end

  test "show filter libelle_procol with matching value includes company" do
    skip "procol_at_date SQL function not in test DB (run db:migrate RAILS_ENV=test)" unless procol_at_date_available?

    sign_in @user

    # company_paris has osf_procol libelle_procol "Redressement judiciaire"
    get list_path(@list_2025), params: { search: { libelle_procol: "Redressement judiciaire" } }

    assert_response :success
    assert_includes @response.body, "Company Paris"
  end

  test "show filter libelle_procol In bonis excludes company in procol" do
    skip "procol_at_date SQL function not in test DB (run db:migrate RAILS_ENV=test)" unless procol_at_date_available?

    sign_in @user

    # company_paris is in procol, so "In bonis" excludes it
    get list_path(@list_2025), params: { search: { libelle_procol: "In bonis" } }

    assert_response :success
    assert_not_includes @response.body, "Company Paris"
    assert_includes @response.body, "Company Ancien"
  end

  test "show filter niveau_alerte includes company with matching alert" do
    sign_in @user

    # company_paris has alert "Alerte seuil F1" in list_test_2025
    get list_path(@list_2025), params: { search: { niveau_alerte: "Alerte seuil F1" } }

    assert_response :success
    assert_includes @response.body, "Company Paris"
  end

  test "show filter niveau_alerte excludes company with other alert" do
    sign_in @user

    get list_path(@list_2025), params: { search: { niveau_alerte: "Alerte seuil F2" } }

    assert_response :success
    assert_not_includes @response.body, "Company Paris"
    assert_includes @response.body, "Company Ancien"
  end

  test "show filter premieres_alertes keeps company only detected over 18 months ago" do
    sign_in @user

    # company_paris appears in list 2025 and list 2024 (within 18 months) → not "première alerte"
    # company_ancien appears in list 2025 and list 2023 (older than 18 months) → "première alerte"
    get list_path(@list_2025), params: { search: { premieres_alertes: "1" } }

    assert_response :success
    assert_includes @response.body, "Company Ancien"
    assert_not_includes @response.body, "Company Paris"
  end

  test "show filter sans_entreprises_recentes keeps company created over 3 years ago" do
    sign_in @user

    AppSetting.create!(entreprises_recentes_filter_date: Date.new(2023, 1, 1))

    # company_paris creation 2020-01-01
    get list_path(@list_2025), params: { search: { sans_entreprises_recentes: "1" } }

    assert_response :success
    assert_includes @response.body, "Company Paris"
  end

  test "show filter sans_delai_urssaf keeps company without delai after list_date" do
    sign_in @user

    # company_paris has osf_delai date_echeance 2025-01-10, list list_date 2025-01-15 → not excluded
    get list_path(@list_2025), params: { search: { sans_delai_urssaf: "1" } }

    assert_response :success
    assert_includes @response.body, "Company Paris"
  end

  test "show filter section_activite_principale excludes company with nil naf_section" do
    sign_in @user

    # company_paris has no naf_section in fixtures (nil); filter by section A excludes it
    get list_path(@list_2025), params: { search: { section_activite_principale: ["A"] } }

    assert_response :success
    assert_includes @response.body, "Aucun résultat trouvé"
  end

  test "show filter liste_retraitee includes company in sjcf for list" do
    sign_in @user

    # company_paris is in sjcf_companies for "Liste test 2025"
    get list_path(@list_2025), params: { search: { liste_retraitee: "1" } }

    assert_response :success
    assert_includes @response.body, "Company Paris"
  end

  test "show with combined filters applies all" do
    sign_in @user

    get list_path(@list_2025), params: {
      search: {
        q: "123",
        effectif_min: 10,
        niveau_alerte: "Alerte seuil F1"
      }
    }

    assert_response :success
    assert_includes @response.body, "Company Paris"
  end

  test "show with combined filters that exclude company shows empty" do
    sign_in @user

    get list_path(@list_2025), params: {
      search: {
        q: "123",
        effectif_min: 60
      }
    }

    assert_response :success
    assert_includes @response.body, "Aucun résultat trouvé"
  end

  test "show pagination per_page and cursor" do
    sign_in @user

    # Only 1 company for Paris user; request small per_page
    get list_path(@list_2025), params: { search: { per_page: 5 } }

    assert_response :success
    assert_includes @response.body, "Company Paris"
  end

  # --- enrich_company (uses enrich_single_company) ---

  test "enrich_company redirects when not authenticated" do
    get enrich_company_list_path(@list_2025), params: { siren: "123456789" }

    assert_redirected_to new_user_session_path
  end

  test "enrich_company returns bad request when siren is blank" do
    sign_in @user

    get enrich_company_list_path(@list_2025), params: { siren: "" }

    assert_response :bad_request
  end

  test "enrich_company returns success and shows alert badge for company with F1 alert" do
    sign_in @user

    # company_paris (123456789) has CompanyScoreEntry with alert "Alerte seuil F1" in list_test_2025
    get enrich_company_list_path(@list_2025), params: { siren: "123456789" }

    assert_response :success
    assert_select "p.fr-badge", text: "Alerte élevée"
  end

  test "enrich_company shows first alert badge when siren only in this list" do
    sign_in @user

    # company_finistere (987654321) is only in list_test_2025, so is_first_alert is true
    get enrich_company_list_path(@list_2025), params: { siren: "987654321" }

    assert_response :success
    assert_select "p.fr-badge", text: "1ère alerte"
  end

  test "enrich_company shows first alert badge when last detection is over 18 months ago" do
    sign_in @user

    # company_ancien (222222222) is in list_test_2023 and list_test_2025 only
    get enrich_company_list_path(@list_2025), params: { siren: "222222222" }

    assert_response :success
    assert_select "p.fr-badge", text: "1ère alerte"
  end

  test "enrich_company shows establishment count when company has active establishments" do
    sign_in @user

    # company_paris has establishments with is_active: true (establishment_paris6, establishment_paris_no_trackings)
    get enrich_company_list_path(@list_2025), params: { siren: "123456789" }

    assert_response :success
    assert_includes @response.body, "établissements en activité"
  end

  test "enrich_company renders turbo frames for badges and establishments" do
    sign_in @user

    get enrich_company_list_path(@list_2025), params: { siren: "123456789" }

    assert_response :success
    assert_select "turbo-frame#company_badges_123456789", count: 1
    assert_select "turbo-frame#company_establishments_123456789", count: 1
  end
end
# rubocop:enable Naming/VariableNumber
