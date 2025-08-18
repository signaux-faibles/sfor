# Test establishments seed file for OSF sync testing
# Creates sequential SIRET numbers for reliable testing

# Only run in development environment
unless Rails.env.development?
  puts "⚠️  Test establishments can only be created in development environment"
  return
end

puts "Creating test establishments for OSF sync testing..."

# Configuration
TEST_COUNT = ENV.fetch('TEST_ESTABLISHMENTS_COUNT', 10_000).to_i
ESTABLISHMENTS_PER_SIREN = 99_999

puts "📊 Target: #{TEST_COUNT} test establishments"

# Get required data
activity_sectors = ActivitySector.all
level_two_and_above_sectors = activity_sectors.where('depth > 1')
departments = Department.all

if level_two_and_above_sectors.empty?
  puts "❌ No activity sectors found. Run other seeds first."
  return
end

if departments.empty?
  puts "❌ No departments found. Run other seeds first."
  return
end

# Clear existing test data (SIRENs starting with 000000)
puts "🧹 Clearing existing test data..."
test_companies = Company.where("siren LIKE '000000%'")
test_establishments = Establishment.where("siren LIKE '000000%'")

puts "   Deleting #{test_establishments.count} test establishments..."
test_establishments.delete_all

puts "   Deleting #{test_companies.count} test companies..."
test_companies.delete_all

# Calculate how many SIRENs we need
sirens_needed = (TEST_COUNT.to_f / ESTABLISHMENTS_PER_SIREN).ceil
puts "🏭 Will use #{sirens_needed} SIRENs (000000001 to #{format('000000%03d', sirens_needed)})"

current_establishment = 1
start_time = Time.current

sirens_needed.times do |siren_index|
  siren_number = siren_index + 1
  base_siren = format("000000%03d", siren_number)
  
  # How many establishments for this SIREN?
  remaining = TEST_COUNT - current_establishment + 1
  batch_size = [remaining, ESTABLISHMENTS_PER_SIREN].min
  
  puts "📋 SIREN #{base_siren}: Creating #{batch_size} establishments..."
  
  # Sample some fixed data for this SIREN
  department = departments.sample
  activity_sector = level_two_and_above_sectors.sample
  level_one_activity_sector = activity_sector.level_one
  
  # Create the company for this SIREN
  company = Company.create!(
    siren: base_siren,
    siret: "#{base_siren}00001", # First establishment SIRET
    raison_sociale: "Test Company SIREN #{base_siren}",
    effectif: rand(50..500),
    activity_sector: activity_sector,
    department: department
  )
  
  # Prepare establishments for bulk insert
  establishments = []
  
  batch_size.times do |i|
    nic = format("%05d", i + 1)
    siret = "#{base_siren}#{nic}"
    global_index = current_establishment + i - 1
    
    establishment_data = {
      department_id: department.id,
      raison_sociale: "Test Establishment #{global_index + 1}",
      siren: base_siren,
      siret: siret,
      commune: "Test City #{global_index % 1000}",
      valeur_score: rand(0.0..1.0).round(2),
      detail_score: { test: true, score: rand(0..100) },
      first_alert: [true, false].sample,
      first_list_entreprise: "test_list",
      first_red_list_entreprise: "test_red_list",
      first_list_etablissement: "test_etab_list",
      first_red_list_etablissement: "test_red_etab_list",
      last_list: "current_list",
      last_alert: "alert_#{rand(1..100)}",
      liste: "liste_#{rand(1..10)}",
      chiffre_affaire: rand(10_000..1_000_000).round(2),
      prev_chiffre_affaire: rand(10_000..1_000_000).round(2),
      arrete_bilan: Date.current - rand(365),
      exercice_diane: rand(1..10),
      variation_ca: rand(-50.0..50.0).round(2),
      resultat_expl: rand(-100_000..500_000).round(2),
      prev_resultat_expl: rand(-100_000..500_000).round(2),
      excedent_brut_d_exploitation: rand(-50_000..200_000).round(2),
      prev_excedent_brut_d_exploitation: rand(-50_000..200_000).round(2),
      effectif: rand(1..100),
      effectif_entreprise: rand(50..500),
      date_entreprise: Date.current - rand(365..1825),
      date_effectif: Date.current - rand(30..365),
      libelle_n5: "Test Activity N5",
      libelle_n1: "Test Activity N1",
      code_activite: "TEST#{rand(10..99)}",
      last_procol: "procol_#{rand(1..50)}",
      date_last_procol: Date.current - rand(30..365),
      activite_partielle: [true, false].sample,
      apconso_heure_consomme: rand(0..160),
      apconso_montant: rand(0..50_000),
      hausse_urssaf: [true, false].sample,
      dette_urssaf: rand(0..10_000).round(2),
      periode_urssaf: Date.current - rand(30..365),
      presence_part_salariale: [true, false].sample,
      alert: "alert_level_#{rand(1..5)}",
      raison_sociale_groupe: "Test Group #{siren_number}",
      territoire_industrie: [true, false].sample,
      code_territoire_industrie: "TI#{rand(10..99)}",
      libelle_territoire_industrie: "Test Territory #{rand(1..20)}",
      statut_juridique_n3: "Test Status N3",
      statut_juridique_n2: "Test Status N2", 
      statut_juridique_n1: "Test Status N1",
      date_ouverture_etablissement: Date.current - rand(365..3650),
      date_creation_entreprise: Date.current - rand(365..3650),
      secteur_covid: "secteur_#{rand(1..10)}",
      etat_administratif: "Actif",
      etat_administratif_entreprise: "Actif",
      has_delai: [true, false].sample,
      activity_sector_id: activity_sector.id,
      level_one_activity_sector_id: level_one_activity_sector.id,
      company_id: company.id,
      is_siege: (i == 0), # First establishment is headquarters
      parent_establishment_id: nil, # Keep it simple for testing
      created_at: Time.current,
      updated_at: Time.current
    }
    
    establishments << establishment_data
  end
  
  # Bulk insert in chunks to avoid memory issues
  establishments.each_slice(5_000) do |chunk|
    Establishment.insert_all(chunk)
  end
  
  current_establishment += batch_size
  
  # Progress update
  progress = ((current_establishment - 1).to_f / TEST_COUNT * 100).round(1)
  elapsed = (Time.current - start_time).round(1)
  rate = ((current_establishment - 1) / elapsed).round(0)
  
  puts "   ✅ Progress: #{progress}% (#{current_establishment - 1}/#{TEST_COUNT}) - #{rate} establishments/sec"
  
  break if current_establishment > TEST_COUNT
end

total_time = (Time.current - start_time).round(2)
final_count = [current_establishment - 1, TEST_COUNT].min

puts "🎉 Test data creation completed!"
puts "📊 Created #{final_count} establishments in #{total_time}s"
puts "⚡ Average rate: #{(final_count / total_time).round(0)} establishments/sec"
puts "💾 Memory usage: #{`ps -o rss= -p #{Process.pid}`.to_i / 1024}MB"

# Verification
companies_created = Company.where("siren LIKE '000000%'").count
establishments_created = Establishment.where("siren LIKE '000000%'").count

puts "✅ Verification:"
puts "   Companies: #{companies_created}"
puts "   Establishments: #{establishments_created}"
puts "   Ready for OSF sync testing!"
