# frozen_string_literal: true

require "test_helper"

class FirstAlertBadgeTest < ActionDispatch::IntegrationTest
  setup do
    @crp_user = users(:user_crp_paris)
    @non_crp_user = users(:user_urssaf_paris)
    @list_2025 = FirstAlertScenarioFixtures.build!
  end

  FirstAlertScenarioFixtures::SCENARIOS.each do |scenario|
    define_method(:"test_enrich_company_#{scenario[:id]}_shows_first_alert_badge_for_crp_when_expected") do
      sign_in @crp_user
      get enrich_company_list_path(@list_2025), params: { siren: scenario[:siren] }

      assert_response :success
      assert_first_alert_badge(expected: scenario[:badge_crp])
    end

    define_method(:"test_company_show_#{scenario[:id]}_shows_first_alert_badge_for_crp_when_expected") do
      sign_in @crp_user
      get company_path(scenario[:siren])

      assert_response :success
      assert_first_alert_badge(expected: scenario[:badge_crp])
    end

    define_method(:"test_company_show_#{scenario[:id]}_shows_first_alert_badge_for_non_crp_when_expected") do
      sign_in @non_crp_user
      get company_path(scenario[:siren])

      assert_response :success
      assert_first_alert_badge(expected: scenario[:badge_non_crp])
    end
  end

  test "non-CRP list show excludes Plans Ratios and Pas d'alerte companies" do
    sign_in @non_crp_user
    get list_path(@list_2025)

    assert_response :success
    FirstAlertScenarioFixtures::SCENARIOS.select { |s| s[:crp_only_list] }.each do |scenario|
      assert_not_includes @response.body, scenario[:siren],
                          "#{scenario[:id]} should be hidden from non-CRP list results"
    end
  end

  test "non-CRP enrich_company shows first alert badge only for F1 F2 scenarios" do
    sign_in @non_crp_user

    FirstAlertScenarioFixtures::SCENARIOS.reject { |s| s[:crp_only_list] }.each do |scenario|
      get enrich_company_list_path(@list_2025), params: { siren: scenario[:siren] }

      assert_response :success, "#{scenario[:id]} enrich should respond"
      assert_first_alert_badge(expected: scenario[:badge_non_crp], message: scenario[:id])
    end
  end

  test "premieres_alertes filter keeps FA01 and excludes FA03 for CRP" do
    sign_in @crp_user

    get list_path(@list_2025), params: { search: { premieres_alertes: "1" } }

    assert_response :success
    assert_includes @response.body, "900000001"
    assert_not_includes @response.body, "900000003"
  end

  test "premieres_alertes filter ignores prior Ratios detection for FA08" do
    sign_in @crp_user

    get list_path(@list_2025), params: { search: { premieres_alertes: "1" } }

    assert_response :success
    assert_includes @response.body, "900000008"
  end

  test "excel export marks FA01 as premiere alerte and FA03 as not" do
    sign_in @crp_user

    companies = Company.joins(:company_lists).where(company_lists: { list_id: @list_2025.id })
    xlsx = Excel::ListGenerator.new(@list_2025, companies, {}, @crp_user).generate
    rows_by_siren = worksheet_rows_by_siren(xlsx)

    assert_equal "1ère alerte", rows_by_siren["900000001"]["Fréquence d'alerte"]
    assert_equal "-", rows_by_siren["900000003"]["Fréquence d'alerte"]
  end

  private

  def assert_first_alert_badge(expected:, message: nil)
    prefix = message ? "#{message}: " : ""
    if expected
      assert_select "p.fr-badge", { text: "1ère alerte", count: 1 }, "#{prefix}expected first alert badge"
    else
      assert_select "p.fr-badge", { text: "1ère alerte", count: 0 }, "#{prefix}did not expect first alert badge"
    end
  end

  def worksheet_rows_by_siren(xlsx)
    rows = worksheet_rows(xlsx)
    headers = rows.first
    rows[1..].to_h do |row|
      row_data = headers.zip(row).to_h
      [row_data["Siren"], row_data]
    end
  end

  def worksheet_rows(xlsx)
    require "zip"
    rows = nil

    Zip::File.open_buffer(StringIO.new(xlsx)) do |zip_file|
      sheet_xml = zip_file.read("xl/worksheets/sheet1.xml")
      document = Nokogiri::XML(sheet_xml)
      document.remove_namespaces!

      rows = document.xpath("//sheetData/row").map do |row|
        row.xpath("c").map { |cell| cell_value(cell) }
      end
    end

    rows
  end

  def cell_value(cell)
    if cell["t"] == "inlineStr"
      cell.at_xpath("is/t")&.text
    else
      cell.at_xpath("v")&.text
    end
  end
end
