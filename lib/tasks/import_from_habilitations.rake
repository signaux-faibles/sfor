# lib/tasks/import_from_habilitations.rake
# Import user data (including roles) from the habilitations xlsx file
# usage : rake users:import file=path/to/your_file.xlsx

module UserImporter
  def create_or_update_user(row)
    email = row["ADRESSE MAIL"]&.strip&.downcase
    segment_name = row["SEGMENT"]

    return if %w[admin keycloakadmin].include?(email) || segment_name == "dreets"

    user = User.find_or_initialize_by(email: email)
    update_user_attributes(user, row)
    setup_user_associations(user, row)
    setup_user_password(user)
    assign_user_roles(user, row)
    save_user(user)
  end

  def update_user_attributes(user, row)
    user.first_name = row["PRENOM"]
    user.last_name = row["NOM"]
    user.level = row["NIVEAU HABILITATION"]
    user.description = row["FONCTION"]
  end

  def setup_user_associations(user, row)
    setup_entity_association(user, row)
    setup_segment_association(user, row)
    assign_networks(user, row["SEGMENT"])
    assign_geo_access(user, row["ACCES GEOGRAPHIQUE"])
  end

  def setup_entity_association(user, row)
    entity_name = row["ENTITES"]
    entity = Entity.find_or_create_by(name: entity_name)
    user.entity = entity
  end

  def setup_segment_association(user, row)
    segment_name = row["SEGMENT"]
    segment = Segment.find_or_create_by(name: segment_name) do |seg|
      seg.network = determine_network_for_segment(segment_name)
    end
    user.segment = segment
  end

  def setup_user_password(user)
    user.password = Devise.friendly_token[0, 20] if user.new_record?
  end

  def save_user(user)
    if user.save
      track_user_creation(user)
    else
      track_error
      puts "✗ Error creating/updating user #{user.email}: #{user.errors.full_messages.join(', ')}"
    end
  end
end

module UserDiscarder
  def discard_users(row)
    create_or_update_user(row)
    email = row["ADRESSE MAIL"]&.downcase
    user = User.find_by(email: email)
    handle_user_discard(user, email)
  end

  def handle_user_discard(user, email)
    if user
      discard_user(user, email)
    else
      track_error
      puts "✗ User not found: #{email}"
    end
  end

  def discard_user(user, email)
    user.discard!
    track_user_discard(user)
  rescue Discard::RecordNotDiscarded => e
    handle_discard_error(user, email, e)
  end

  def handle_discard_error(user, email, error)
    track_error
    if user.discarded?
      puts "✗ User is already discarded: #{email}"
    else
      puts "✗ Failed to discard user: #{email}. Error: #{error.message}"
    end
  end
end

module RoleManager
  def assign_user_roles(user, row)
    roles = determine_roles(user, row)
    user.roles = Role.where(name: roles)
  end

  def determine_roles(user, row)
    roles = base_roles_for_level(user.level)
    roles += additional_roles_for_level(user.level)
    roles += geo_access_role(user)
    roles += scope_roles(row)
    roles.uniq
  end

  def base_roles_for_level(level)
    habilitations = {
      "a" => %w[bdf detection dgefp pge score urssaf],
      "b" => %w[detection dgefp pge score]
    }
    habilitations[level.downcase] || []
  end

  def additional_roles_for_level(level)
    case level.downcase
    when "a"
      %w[urssaf dgefp bdf]
    when "b"
      %w[dgefp]
    else
      []
    end
  end

  def geo_access_role(user)
    return [] unless %w[a b].include?(user.level.downcase)
    return [] if user.geo_access.nil?

    [user.geo_access.name]
  end

  def scope_roles(row)
    scope = row["SCOPE"].to_s.split(",").map(&:strip)
    scope == [""] ? [] : scope
  end
end

module NetworkManager
  def assign_geo_access(user, geo_access_name)
    geo_access = GeoAccess.find_by(name: geo_access_name)

    if geo_access.nil?
      puts "Accès géographique inconnu: #{geo_access_name} pour l'utilisateur #{user.email}"
      return
    end

    user.departments = geo_access.departments
    user.geo_access = geo_access
  end

  def assign_networks(user, segment_name)
    if segment_name.downcase != "dreets_reseaucrp" && user.networks.exclude?(@codefi_network)
      user.networks << @codefi_network
    end

    network = determine_network_for_segment(segment_name)
    if network
      user.networks << network unless user.networks.include?(network)
    else
      puts "No network found for segment #{segment_name}."
    end
  end

  def determine_network_for_segment(segment_name)
    network_mapping[segment_name.downcase]
  end

  def network_mapping # rubocop:disable Metrics/MethodLength
    {
      "crp" => @crp_network,
      "dreets_reseaucrp" => @crp_network,
      "finances" => @crp_network,
      "urssaf" => @urssaf_network,
      "bdf" => @banque_de_france_network,
      "dgfip" => @dgfip_network,
      "darp" => @dgefp_network,
      "ddets" => @dgefp_network,
      "dgefp" => @dgefp_network,
      "dreets" => @dgefp_network
    }
  end
end

class ImportHelper
  include UserImporter
  include UserDiscarder
  include RoleManager
  include NetworkManager

  def initialize(file_path)
    @file_path = file_path
    initialize_networks
    initialize_stats
  end

  def import
    workbook = parse_workbook
    process_worksheets(workbook)
    display_stats
  end

  private

  def initialize_stats
    @stats = {
      created: 0,
      updated: 0,
      updated_discarded: 0,
      errors: 0
    }
  end

  def display_stats
    puts "\n=== Import Statistics ==="
    puts "Users created: #{@stats[:created]}"
    puts "Users updated: #{@stats[:updated]}"
    puts "  - Among which discarded: #{@stats[:updated_discarded]}"
    puts "Errors encountered: #{@stats[:errors]}"
    puts "=====================\n"
  end

  def increment_stat(key)
    @stats[key] += 1
  end

  def track_error
    increment_stat(:errors)
  end

  def track_user_creation(user)
    if user.saved_change_to_id?
      increment_stat(:created)
      puts "✓ Created new user: #{user.email}"
    else
      increment_stat(:updated)
      puts "↻ Updated existing user: #{user.email}"
    end
  end

  def track_user_discard(_user)
    increment_stat(:updated_discarded)
    puts "  - User was discarded"
  end

  def initialize_networks
    @codefi_network = Network.find_or_create_by(name: "CODEFI")
    @crp_network = Network.find_or_create_by(name: "CRP")
    @urssaf_network = Network.find_or_create_by(name: "URSSAF")
    @banque_de_france_network = Network.find_or_create_by(name: "Banque de France")
    @dgfip_network = Network.find_or_create_by(name: "DGFiP")
    @dgefp_network = Network.find_or_create_by(name: "DGEFP")
  end

  def parse_workbook
    RubyXL::Parser.parse(@file_path)
  end

  def process_worksheets(workbook)
    users_worksheet = workbook["utilisateurs"]
    discard_worksheet = workbook["historique suppressions"]

    users_header = extract_header(users_worksheet)
    discard_header = extract_header(discard_worksheet)

    puts "\n=== Processing Users ==="
    import_users(users_worksheet, users_header)

    puts "\n=== Processing Discards ==="
    discard_users_from_worksheet(discard_worksheet, discard_header)
  end

  def extract_header(worksheet)
    worksheet.sheet_data[0].cells.map { |cell| cell&.value }
  end

  def import_users(worksheet, header)
    worksheet.sheet_data.rows[1..].each do |row|
      break if row.nil? || row.cells[0].nil? || row.cells[0].value.nil?

      process_row(row, header)
    end
  end

  def process_row(row, header)
    row_data = extract_row_data(row, header)
    create_or_update_user(row_data)
  end

  def extract_row_data(row, header)
    header.zip(row.cells.map { |cell| cell && cell.value }).to_h
  end

  def discard_users_from_worksheet(worksheet, header)
    worksheet.sheet_data.rows[1..].each do |row|
      break if row.nil? || row.cells[0].nil? || row.cells[0].value.nil?

      process_discard_row(row, header)
    end
  end

  def process_discard_row(row, header)
    row_data = extract_row_data(row, header)
    discard_users(row_data)
  end
end

namespace :users do
  desc "Import users from an Excel file using rubyXL"
  task import: :environment do
    file_path = ENV.fetch("file", nil)

    if file_path.nil?
      puts "Please provide a file path using file=path/to/file.xlsx"
      exit
    end

    ImportHelper.new(file_path).import
  end
end
