# frozen_string_literal: true

require "test_helper"

class CompanyListTest < ActiveSupport::TestCase
  test "meaningful_alert returns true for F1 F2 Plans and Ratios" do
    assert CompanyList.meaningful_alert?("Alerte seuil F1")
    assert CompanyList.meaningful_alert?("Alerte seuil F2")
    assert CompanyList.meaningful_alert?("Plans")
    assert CompanyList.meaningful_alert?("Ratios")
  end

  test "meaningful_alert returns false for Pas d'alerte blank and unknown values" do
    assert_not CompanyList.meaningful_alert?("Pas d'alerte")
    assert_not CompanyList.meaningful_alert?(nil)
    assert_not CompanyList.meaningful_alert?("")
    assert_not CompanyList.meaningful_alert?("Inconnu")
  end

  test "first_alert_eligible returns true for F1 and F2 only" do
    assert CompanyList.first_alert_eligible?("Alerte seuil F1")
    assert CompanyList.first_alert_eligible?("Alerte seuil F2")
    assert_not CompanyList.first_alert_eligible?("Plans")
    assert_not CompanyList.first_alert_eligible?("Ratios")
    assert_not CompanyList.first_alert_eligible?("Pas d'alerte")
    assert_not CompanyList.first_alert_eligible?(nil)
  end
end
