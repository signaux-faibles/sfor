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
    worksheet = workbook[0] # Habilitations are in the first sheet of the xlsx file

    # Extract headers from the first row
    header = worksheet.sheet_data[0].cells.map { |cell| cell && cell.value }

    worksheet.sheet_data.rows[1..-1].each do |row|
      # Check if the first cell in the row is empty
      break if row.cells[0].nil? || row.cells[0].value.nil?

      row_data = Hash[header.zip(row.cells.map { |cell| cell && cell.value })]
      create_or_update_user(row_data)
    end

    puts "Users import completed!"
  end

  def create_or_update_user(row)
    email = row['ADRESSE MAIL']&.downcase
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
    geo_access = GeoAccess.find_or_create_by(name: geo_access_name)
    user.geo_access = geo_access

    assign_region_and_departments(user, geo_access_name)

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

  def assign_region_and_departments(user, geo_access_name)
    if geo_access_name == 'France entière'
      user.regions = Region.all
      user.departments = Department.all
    else
      region = Region.find_by(libelle: geo_access_name)
      if region
        user.regions << region unless user.regions.include?(region)
        user.departments += region.departments unless (user.departments & region.departments).any?
      else
        department = Department.find_by(code: geo_access_name)
        if department
          user.departments << department unless user.departments.include?(department)
          user.regions << department.region unless user.regions.include?(department.region)
        else
          puts "Géographie inconnue: #{geo_access_name} pour l'utilisateur #{user.email}"
        end
      end
    end
  end

  def determine_roles(user, row)
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