# lib/tasks/import_from_habilitations.rake
# Import user data (including roles) from the habilitations xlsx file
# usage : rake users:import file=path/to/your_file.xlsx

namespace :users do
  desc "Import users from an Excel file using rubyXL"
  task import: :environment do
    file_path = ENV['file']

    if file_path.nil?
      puts "Please provide a file path using file=path/to/file.xlsx"
      exit
    end

    workbook = RubyXL::Parser.parse(file_path)
    users_worksheet = workbook['utilisateurs']
    discard_worksheet = workbook['historique suppressions']

    users_header = users_worksheet.sheet_data[0].cells.map { |cell| cell && cell.value }
    discard_header = discard_worksheet.sheet_data[0].cells.map { |cell| cell && cell.value }

    users_worksheet.sheet_data.rows[1..-1].each do |row|
      break if row.nil? || row.cells[0].nil? || row.cells[0].value.nil?

      row_data = Hash[users_header.zip(row.cells.map { |cell| cell && cell.value })]
      create_or_update_user(row_data)
    end

    discard_worksheet.sheet_data.rows[1..-1].each do |row|
      break if row.nil? || row.cells[0].nil? || row.cells[0].value.nil?

      row_data = Hash[discard_header.zip(row.cells.map { |cell| cell && cell.value })]
      discard_users(row_data)
    end

    puts "Users import and discard completed!"
  end

  def create_or_update_user(row)
    email = row['ADRESSE MAIL']&.downcase
    puts "Creating new user: #{email}"
    return if %w[admin keycloakadmin].include?(email)

    user = User.find_or_initialize_by(email: email)
    user.first_name = row['PRENOM']
    user.last_name = row['NOM']
    user.level = row['NIVEAU HABILITATION']
    user.description = row['FONCTION']

    # Entity association
    entity_name = row['ENTITES']
    entity = Entity.find_or_create_by(name: entity_name)
    user.entity = entity

    # Segment association
    segment_name = row['SEGMENT']
    segment = Segment.find_or_create_by(name: segment_name)
    user.segment = segment

    # GeoAccess association
    geo_access_name = row['ACCES GEOGRAPHIQUE']

    assign_geo_access(user, geo_access_name)

    # Password management for Devise
    if user.new_record?
      user.password = Devise.friendly_token[0, 20]
    end

    # Assign roles the same way IamUpdater does it (signaux-faibles/IamUpdater/blob/master/user.go)
    roles = determine_roles(user, row)
    user.roles = Role.where(name: roles)

    unless user.save
      puts "Erreur lors de la création/mise à jour de l'utilisateur #{user.email}: #{user.errors.full_messages.join(', ')}"
    end
  end

  def discard_users(row)
    email = row['ADRESSE MAIL']&.downcase
    puts "Discarding user: #{email}"
    user = User.find_by(email: email)
    if user
      begin
        user.discard!
        puts "User discarded successfully"
      rescue Discard::RecordNotDiscarded => e
        if user.discarded?
          puts "User is already discarded: #{email}"
        else
          puts "Failed to discard user: #{email}. Error: #{e.message}"
        end
      end
    else
      puts "User not found: #{email}"
    end
  end

  def assign_geo_access(user, geo_access_name)
    puts "Assigning geo access #{geo_access_name}"
    geo_access = GeoAccess.find_by(name: geo_access_name)

    if geo_access.nil?
      puts "Accès géographique inconnu: #{geo_access_name} pour l'utilisateur #{user.email}"
      return
    end

    if geo_access_name.downcase == 'France entière'
      user.departments = Department.all
    else
      user.departments = geo_access.departments
    end

    user.geo_access = geo_access
  end

  def determine_roles(user, row)
    puts "Assigning roles..."
    habilitations = {
      "a" => ["bdf", "detection", "dgefp", "pge", "score", "urssaf"],
      "b" => ["detection", "dgefp", "pge", "score"]
    }

    roles = habilitations[user.level.downcase] || []

    if user.level.downcase == "a"
      roles += ["urssaf", "dgefp", "bdf"]
    elsif user.level.downcase == "b"
      roles << "dgefp"
    end

    if ["a", "b"].include?(user.level.downcase)
      roles += ["score", "detection", "pge"]
      unless user.geo_access.nil?
        roles << user.geo_access.name
      end
    end

    scope = row['SCOPE'].to_s.split(',').map(&:strip)
    roles += scope unless scope == [""]

    roles.uniq
  end
end