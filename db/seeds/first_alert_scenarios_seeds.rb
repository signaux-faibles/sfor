# frozen_string_literal: true

# Seeds deterministic data to manually test the "1ère alerte" badge (development only).
#
# Loaded from db/seeds.rb — run with: bin/rails db:seed
#
# Test users (password for both: Test1234#dev):
#   demo.crp@signaux-faibles.local    — CRP (sees Plans/Ratios)
#   demo.urssaf@signaux-faibles.local — non-CRP (F1/F2 only)
#
# Browse list "Liste démo 1ère alerte 2025" for list/enrich testing.
# Company pages (/companies/9000000xx) use the globally latest list (highest `code`),
# so demo list codes are prefixed with ZZZZ_ to sort above typical local imports.

module FirstAlertScenariosSeeds
  PASSWORD = "Test1234#dev"
  DEPARTMENT_CODE = "75"
  SIREN_PREFIX = "9000000"
  # Sort above typical imported list codes so company#show uses demo data.
  LIST_CODE_PREFIX = "ZZZZ_DEMO_FA_"
  LEGACY_LIST_CODES = %w[DEMO_FA_2023 DEMO_FA_2024 DEMO_FA_2025].freeze

  LISTS = [
    { label: "Liste démo 1ère alerte 2023", code: "#{LIST_CODE_PREFIX}2023", list_date: Date.new(2023, 6, 1) },
    { label: "Liste démo 1ère alerte 2024", code: "#{LIST_CODE_PREFIX}2024", list_date: Date.new(2024, 6, 1) },
    { label: "Liste démo 1ère alerte 2025", code: "#{LIST_CODE_PREFIX}2025", list_date: Date.new(2025, 1, 15) }
  ].freeze

  # rubocop:disable Layout/LineLength
  SCENARIOS = [
    { siren: "900000001", name: "FA01 Premiere alerte F1", entries: { "Liste démo 1ère alerte 2025" => "Alerte seuil F1" }, badge_crp: true, badge_non_crp: true, notes: "F1 seul, jamais détecté avant" },
    { siren: "900000002", name: "FA02 F1 apres Plans", entries: { "Liste démo 1ère alerte 2024" => "Plans", "Liste démo 1ère alerte 2025" => "Alerte seuil F1" }, badge_crp: true, badge_non_crp: true, notes: "Plans antérieur ignoré" },
    { siren: "900000003", name: "FA03 Re-detection F1", entries: { "Liste démo 1ère alerte 2024" => "Alerte seuil F1", "Liste démo 1ère alerte 2025" => "Alerte seuil F1" }, badge_crp: false, badge_non_crp: false, notes: "F1 antérieur < 18 mois bloque le badge" },
    { siren: "900000004", name: "FA04 F1 apres 18 mois", entries: { "Liste démo 1ère alerte 2023" => "Alerte seuil F1", "Liste démo 1ère alerte 2025" => "Alerte seuil F1" }, badge_crp: true, badge_non_crp: true, notes: "F1 antérieur > 18 mois, badge à nouveau" },
    { siren: "900000005", name: "FA05 Plans apres Plans", entries: { "Liste démo 1ère alerte 2024" => "Plans", "Liste démo 1ère alerte 2025" => "Plans" }, badge_crp: false, badge_non_crp: false, notes: "Plans exclus du badge 1ère alerte" },
    { siren: "900000006", name: "FA06 Plans seul", entries: { "Liste démo 1ère alerte 2025" => "Plans" }, badge_crp: false, badge_non_crp: false, notes: "Plans exclus du badge 1ère alerte" },
    { siren: "900000007", name: "FA07 Ratios apres Ratios", entries: { "Liste démo 1ère alerte 2024" => "Ratios", "Liste démo 1ère alerte 2025" => "Ratios" }, badge_crp: false, badge_non_crp: false, notes: "Ratios exclus du badge 1ère alerte" },
    { siren: "900000008", name: "FA08 F1 apres Ratios", entries: { "Liste démo 1ère alerte 2024" => "Ratios", "Liste démo 1ère alerte 2025" => "Alerte seuil F1" }, badge_crp: true, badge_non_crp: true, notes: "Ratios antérieur ignoré" },
    { siren: "900000009", name: "FA09 Pas d'alerte courant", entries: { "Liste démo 1ère alerte 2025" => "Pas d'alerte" }, badge_crp: false, badge_non_crp: false, notes: "Pas d'alerte courant: jamais de badge" },
    { siren: "900000010", name: "FA10 F1 apres Pas d'alerte", entries: { "Liste démo 1ère alerte 2024" => "Pas d'alerte", "Liste démo 1ère alerte 2025" => "Alerte seuil F1" }, badge_crp: true, badge_non_crp: true, notes: "Pas d'alerte antérieur ignoré" },
    { siren: "900000011", name: "FA11 F1 apres F2", entries: { "Liste démo 1ère alerte 2024" => "Alerte seuil F2", "Liste démo 1ère alerte 2025" => "Alerte seuil F1" }, badge_crp: false, badge_non_crp: false, notes: "F2 antérieur bloque le badge" }
  ].freeze
  # rubocop:enable Layout/LineLength

  DEMO_USER_EMAILS = %w[
    demo.crp@signaux-faibles.local
    demo.urssaf@signaux-faibles.local
  ].freeze

  module_function

  def run
    puts "=== Seeding 1ère alerte demo scenarios ==="

    ActiveRecord::Base.transaction do
      clear_demo_data!
      lists_by_label = upsert_lists
      department = Department.find_by!(code: DEPARTMENT_CODE)
      geo_access = GeoAccess.find_by!(name: DEPARTMENT_CODE)
      upsert_test_users!(department:, geo_access:)

      SCENARIOS.each do |scenario|
        upsert_company!(scenario:, department:)
        upsert_score_entries!(scenario:, lists_by_label:)
        upsert_company_lists!(scenario:, lists_by_label:)
      end

      lists_by_label.each_value { |list| CompanyLists::FirstAlertComputer.backfill_list!(list) }

      print_summary(lists_by_label)
    end
  end

  # Remove previous demo rows so scenario changes don't leave stale list/score data.
  def clear_demo_data!
    sirens = SCENARIOS.map { |scenario| scenario[:siren] }
    list_codes = LISTS.map { |list| list[:code] } + LEGACY_LIST_CODES
    list_labels = LISTS.map { |list| list[:label] }
    demo_list_ids = List.where(code: list_codes).pluck(:id)

    puts "Clearing previous demo data (#{sirens.size} sirens, #{list_codes.size} lists)..."

    CompanyListRating.where(siren: sirens).delete_all
    CompanyListRating.where(list_name: list_labels).delete_all
    CompanyList.where(siren: sirens).delete_all
    CompanyList.where(list_id: demo_list_ids).delete_all if demo_list_ids.any?
    CompanyScoreEntry.where(siren: sirens).delete_all
    CompanyScoreEntry.where(list_name: list_labels).delete_all
    Establishment.where(siren: sirens).delete_all
    Company.where(siren: sirens).delete_all
    List.where(code: list_codes).delete_all

    User.where(email: DEMO_USER_EMAILS).find_each do |user|
      user.network_memberships.delete_all
      user.user_departments.delete_all
      user.destroy!
    end
  end

  def upsert_lists
    LISTS.each_with_object({}) do |attrs, acc|
      list = List.find_or_initialize_by(code: attrs[:code])
      list.assign_attributes(label: attrs[:label], list_date: attrs[:list_date], sjcf_filter_active: false)
      list.save!
      acc[attrs[:label]] = list
    end
  end

  def upsert_test_users!(department:, geo_access:)
    codefi = Network.find_by!(name: "CODEFI")
    crp = Network.find_by!(name: "CRP")
    urssaf = Network.find_or_create_by!(name: "URSSAF") { |n| n.active = false }
    dreets = Entity.find_by!(name: "DREETS")
    crp_segment = Segment.find_by!(name: "crp", network: crp)
    urssaf_segment = Segment.find_or_create_by!(name: "urssaf", network: urssaf)

    upsert_user!(
      email: "demo.crp@signaux-faibles.local",
      first_name: "Demo",
      last_name: "CRP",
      entity: dreets,
      segment: crp_segment,
      geo_access:,
      department:,
      networks: [codefi, crp]
    )

    upsert_user!(
      email: "demo.urssaf@signaux-faibles.local",
      first_name: "Demo",
      last_name: "URSSAF",
      entity: dreets,
      segment: urssaf_segment,
      geo_access:,
      department:,
      networks: [codefi, urssaf]
    )
  end

  def upsert_user!(email:, first_name:, last_name:, entity:, segment:, geo_access:, department:, networks:)
    user = User.find_or_initialize_by(email:)
    user.assign_attributes(
      first_name:,
      last_name:,
      entity:,
      segment:,
      geo_access:,
      password: PASSWORD,
      password_confirmation: PASSWORD
    )
    user.save!
    user.departments = [department]
    user.networks = networks
    user
  end

  def upsert_company!(scenario:, department:)
    now = Time.current
    Company.upsert(
      {
        siren: scenario[:siren],
        raison_sociale: scenario[:name],
        department: department.code,
        statut_juridique: "5710",
        creation: Date.new(2018, 1, 1),
        is_active: true,
        created_at: now,
        updated_at: now
      },
      unique_by: :siren
    )

    siret = "#{scenario[:siren]}00001"
    Establishment.upsert(
      {
        siret:,
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
      entry.assign_attributes(
        score: default_score_for(alert),
        alert:
      )
      entry.save!
    end
  end

  def upsert_company_lists!(scenario:, lists_by_label:)
    scenario[:entries].each do |list_label, alert|
      list = lists_by_label.fetch(list_label)
      company_list = CompanyList.find_or_initialize_by(siren: scenario[:siren], list_id: list.id)
      company_list.assign_attributes(
        score: default_score_for(alert),
        alert:,
        department: DEPARTMENT_CODE
      )
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

  def print_summary(lists_by_label)
    latest_demo_list = lists_by_label.fetch("Liste démo 1ère alerte 2025")
    global_latest_list = List.order(code: :desc).first

    puts ""
    puts "Test users (password: #{PASSWORD}):"
    puts "  CRP     → demo.crp@signaux-faibles.local"
    puts "  non-CRP → demo.urssaf@signaux-faibles.local"
    puts ""
    puts "Demo list (for list/enrich/filter testing):"
    puts "  #{latest_demo_list.label} (id=#{latest_demo_list.id}, code=#{latest_demo_list.code})"
    puts "  /lists/#{latest_demo_list.id}"
    warn_latest_list_conflict(latest_demo_list, global_latest_list)
    puts ""
    puts "Companies (SIREN → badge CRP / non-CRP on demo list + company page when demo list is global latest):"
    SCENARIOS.each do |scenario|
      crp = scenario[:badge_crp] ? "Oui" : "Non"
      non_crp = scenario[:badge_non_crp] ? "Oui" : "Non"
      puts "  #{scenario[:siren]}  #{scenario[:name]}"
      puts "    Badge: CRP=#{crp}, non-CRP=#{non_crp} — #{scenario[:notes]}"
      puts "    /companies/#{scenario[:siren]}"
    end
    puts "=== Done ==="
  end

  def warn_latest_list_conflict(demo_list, global_latest_list)
    return if global_latest_list&.id == demo_list.id

    puts ""
    puts "WARNING: Another list is the global 'latest' (used by /companies/9000000xx):"
    puts "  #{global_latest_list&.label} (code=#{global_latest_list&.code})"
    puts "  Demo companies are NOT in that list — company page badges may be wrong."
    puts "  Prefer testing from /lists/#{demo_list.id}, or use a higher demo list code."
  end
end

FirstAlertScenariosSeeds.run if Rails.env.development?
