# frozen_string_literal: true

# Builds the 11 deterministic "1ère alerte" scenarios in the test DB.
# Keep in sync with db/seeds/first_alert_scenarios_seeds.rb (SCENARIOS).
module FirstAlertScenarioFixtures
  LIST_CODE_PREFIX = "ZZZZ_FA_TEST_"
  DEPARTMENT_CODE = "75"

  LISTS = [
    { label: "Liste FA test 2023", code: "#{LIST_CODE_PREFIX}2023", list_date: Date.new(2023, 6, 1) },
    { label: "Liste FA test 2024", code: "#{LIST_CODE_PREFIX}2024", list_date: Date.new(2024, 6, 1) },
    { label: "Liste FA test 2025", code: "#{LIST_CODE_PREFIX}2025", list_date: Date.new(2025, 1, 15) }
  ].freeze

  # rubocop:disable Layout/LineLength
  SCENARIOS = [
    { id: "FA01", siren: "900000001", entries: { "Liste FA test 2025" => "Alerte seuil F1" }, badge_crp: true, badge_non_crp: true },
    { id: "FA02", siren: "900000002", entries: { "Liste FA test 2024" => "Plans", "Liste FA test 2025" => "Alerte seuil F1" }, badge_crp: true, badge_non_crp: true },
    { id: "FA03", siren: "900000003", entries: { "Liste FA test 2024" => "Alerte seuil F1", "Liste FA test 2025" => "Alerte seuil F1" }, badge_crp: false, badge_non_crp: false },
    { id: "FA04", siren: "900000004", entries: { "Liste FA test 2023" => "Alerte seuil F1", "Liste FA test 2025" => "Alerte seuil F1" }, badge_crp: true, badge_non_crp: true },
    { id: "FA05", siren: "900000005", entries: { "Liste FA test 2024" => "Plans", "Liste FA test 2025" => "Plans" }, badge_crp: true, badge_non_crp: false, crp_only_list: true },
    { id: "FA06", siren: "900000006", entries: { "Liste FA test 2025" => "Plans" }, badge_crp: true, badge_non_crp: false, crp_only_list: true },
    { id: "FA07", siren: "900000007", entries: { "Liste FA test 2024" => "Ratios", "Liste FA test 2025" => "Ratios" }, badge_crp: true, badge_non_crp: false, crp_only_list: true },
    { id: "FA08", siren: "900000008", entries: { "Liste FA test 2024" => "Ratios", "Liste FA test 2025" => "Alerte seuil F1" }, badge_crp: true, badge_non_crp: true },
    { id: "FA09", siren: "900000009", entries: { "Liste FA test 2025" => "Pas d'alerte" }, badge_crp: false, badge_non_crp: false, crp_only_list: true },
    { id: "FA10", siren: "900000010", entries: { "Liste FA test 2024" => "Pas d'alerte", "Liste FA test 2025" => "Alerte seuil F1" }, badge_crp: true, badge_non_crp: true },
    { id: "FA11", siren: "900000011", entries: { "Liste FA test 2024" => "Alerte seuil F2", "Liste FA test 2025" => "Alerte seuil F1" }, badge_crp: false, badge_non_crp: false }
  ].freeze
  # rubocop:enable Layout/LineLength

  module_function

  def build!
    lists_by_label = upsert_lists
    department = Department.find_by!(code: DEPARTMENT_CODE)

    SCENARIOS.each do |scenario|
      upsert_company!(scenario:, department:)
      upsert_score_entries!(scenario:, lists_by_label:)
      upsert_company_lists!(scenario:, lists_by_label:)
    end

    lists_by_label.fetch("Liste FA test 2025")
  end

  def upsert_lists
    LISTS.each_with_object({}) do |attrs, acc|
      list = List.find_or_initialize_by(code: attrs[:code])
      list.assign_attributes(label: attrs[:label], list_date: attrs[:list_date], sjcf_filter_active: false)
      list.save!
      acc[attrs[:label]] = list
    end
  end

  def upsert_company!(scenario:, department:)
    now = Time.current
    Company.upsert(
      {
        siren: scenario[:siren],
        raison_sociale: scenario[:id],
        department: department.code,
        statut_juridique: "5710",
        creation: Date.new(2018, 1, 1),
        is_active: true,
        created_at: now,
        updated_at: now
      },
      unique_by: :siren
    )

    Establishment.upsert(
      {
        siret: "#{scenario[:siren]}00001",
        siren: scenario[:siren],
        departement: department.code,
        siege: true,
        is_active: true,
        created_at: now,
        updated_at: now
      },
      unique_by: :siret
    )
  end

  def upsert_score_entries!(scenario:, lists_by_label:)
    scenario[:entries].each do |list_label, alert|
      list = lists_by_label.fetch(list_label)
      periode = list.list_date.strftime("%Y-%m")

      entry = CompanyScoreEntry.find_or_initialize_by(
        siren: scenario[:siren],
        list_name: list.label,
        periode:
      )
      entry.assign_attributes(score: default_score_for(alert), alert:)
      entry.save!
    end
  end

  def upsert_company_lists!(scenario:, lists_by_label:)
    scenario[:entries].each do |list_label, alert|
      list = lists_by_label.fetch(list_label)
      company_list = CompanyList.find_or_initialize_by(siren: scenario[:siren], list_id: list.id)
      company_list.assign_attributes(score: default_score_for(alert), alert:)
      company_list.save!
    end
  end

  def default_score_for(alert)
    case alert
    when "Alerte seuil F1" then 90.0
    when "Alerte seuil F2" then 70.0
    when "Plans" then 55.0
    when "Ratios" then 50.0
    else 40.0
    end
  end
end
