# lib/tasks/import_from_wekan.rake
# Import data from wekan mongo db
# usage : rake import_from_wekan:users

require "mongo"

class ImportEstablishmentTrackingsService # rubocop:disable Metrics/ClassLength
  def initialize
    mongo_host = ENV["WEKAN_MONGO_DB_HOST"] || "10.2.0.231"
    mongo_port = ENV["WEKAN_MONGO_DB_PORT"] || "27017"
    mongo_db_name = ENV["WEKAN_MONGO_DB_NAME"] || "test"
    mongo_user = ENV["WEKAN_MONGO_DB_USER"] || "root"
    mongo_password = ENV["WEKAN_MONGO_DB_PASSWORD"] || "password"

    # PROD
    @mongo_client = Mongo::Client.new(["#{mongo_host}:#{mongo_port}"], database: mongo_db_name, user: mongo_user,
                                                                       password: mongo_password, auth_source: "admin")

    # DEV
    # @mongo_client = Mongo::Client.new([ "#{mongo_host}:#{mongo_port}" ], database: mongo_db_name)
  end

  def perform(board_title) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    puts "Starting import for board: #{board_title}"

    boards = @mongo_client[:boards]
    swimlanes = @mongo_client[:swimlanes]
    cards = @mongo_client[:cards]
    users = @mongo_client[:users]
    lists = @mongo_client[:lists]
    card_comments = @mongo_client[:card_comments]
    custom_fields = @mongo_client[:customFields]

    sf_siret_regex = /(\d{14})/
    extract_department_from_swimlane_title_regex = /(\d+[A|B]?) \(.*\)/

    boards_ids = boards.find({ title: { "$regex": "^#{board_title}" } }).to_a.pluck(:_id)

    # Vérification : arrêter l'import si aucun tableau n'est trouvé
    if boards_ids.empty?
      puts "No board found with title matching '#{board_title}'. Stopping import."
      return
    end

    puts "Found #{boards_ids.count} board(s) matching '#{board_title}'. Proceeding with import..."

    unique_emails = Set.new

    swimlanes.find({ boardId: { "$in": boards_ids } }).sort(title: 1).each do |swimlane| # rubocop:disable Metrics/BlockLength
      puts swimlane[:title]
      boards.find(_id: swimlane[:boardId]).first[:labels].to_h { |obj| [obj["_id"], obj["name"]] }

      title_match = swimlane[:title].match(extract_department_from_swimlane_title_regex)
      unless title_match
        puts "No department information found in swimlane title: #{swimlane[:title]}"
        next
      end

      department_string = title_match[1]
      department = Department.find_by(code: department_string)

      unless department
        puts "Department not found for code: #{department_string}"
        next
      end

      cards.find({ swimlaneId: swimlane[:_id] }).each do |card|
        custom_field_siret = card[:customFields].find do |custom_field|
          custom_field["value"] =~ sf_siret_regex
        end&.dig(:value)

        if custom_field_siret&.match(sf_siret_regex)
          siret = custom_field_siret&.match(sf_siret_regex)&.[](1)
          siren = siret[0, 9]

          company = create_company(card, department, siren, siret)

          establishment = create_establishment(card, company, department, siren, siret)

          mongo_creator = users.find({ _id: card[:userId] }).first
          creator = User.find_by(email: mongo_creator[:username])

          if creator
            establishment_tracking = create_establishment_tracking(card, creator, establishment, lists, siret, users,
                                                                   custom_fields)
            if establishment_tracking.present?
              create_summary(card, establishment_tracking, siret)
              create_all_comments(card, card_comments, establishment_tracking, siret, users)
              # create_all_labels(board_label, card, establishment_tracking)
            else
              puts "Failed to create EstablishmentTracking for card #{card[:title]} (SIRET: #{siret})."
            end
          else
            unique_emails.add(mongo_creator[:username])
          end

        else
          puts "Aucun siret correspondant trouvé pour l'entreprise #{card[:title]}"
          # puts card[:customFields]
          # puts card[:customFields].find { |customField| customField["value"] =~ sf_siret_regex }
        end
      end
    end
    puts "Les utilisateurs qui n'existent pas dans rails sont :\n #{unique_emails}"

    @mongo_client.close

    puts "Wekan crp cards import completed!"
  end

  private

  def create_company(card, department, siren, siret)
    company = Company.find_or_initialize_by(siren: siren)
    company.siren = siren
    company.siret = siret
    company.department = department
    puts "Impossible de créer l'entreprise #{siren} #{card[:title]}" unless company.save
    company
  end

  def create_establishment(card, company, department, siren, siret) # rubocop:disable Metrics/MethodLength
    establishment = Establishment.find_or_initialize_by(siret: siret)
    establishment.siren = siren
    establishment.siret = siret
    establishment.raison_sociale = card[:title]
    establishment.department = department
    establishment.company = company
    if establishment.save
      # puts "    Création de l'établissement pour #{siret} #{card[:title]}"
    else
      puts "Impossible de créer l'établissement #{siret} #{card[:title]}"
    end
    establishment
  end

  def create_establishment_tracking(card, creator, establishment, lists, siret, users, custom_fields) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity,Metrics/ParameterLists,Metrics/MethodLength
    puts "Processing siret #{siret} with card #{card[:title]}."
    wekan_status = lists.find(_id: card[:listId]).first[:title]

    if wekan_status == "Suivi terminé" && !card[:archived]

      puts "Processing siret #{siret} wekan status is #{wekan_status} and card is not archived."

      establishment_tracking = EstablishmentTracking.new(establishment: establishment)
      establishment_tracking.creator = creator
      establishment_tracking.state = "completed"

      # Participants and Referents
      mongo_participants = users.find({ _id: { "$in": card[:members] } }).to_a.pluck(:username)
      participants = User.where(email: mongo_participants)
      establishment_tracking.participants = participants.empty? ? [creator] : participants
      mongo_referents = users.find({ _id: { "$in": card[:assignees] } }).to_a.pluck(:username)
      referents = User.where(email: mongo_referents)
      establishment_tracking.referents = referents.empty? ? [creator] : referents

      # Determine dates
      establishment_tracking.start_date = card[:startAt] || card[:createdAt]
      establishment_tracking.end_date = card[:endAt]

      establishment_tracking.modified_at = card[:modifiedAt]
      establishment_tracking.instance_variable_set(:@skip_modified_at_update, true)

      # Contact details
      id_of_contact = Set.new(custom_fields.find({ "name" => "Contact" }).to_a.pluck("_id"))
      contact_field = card[:customFields].find { |custom_field| id_of_contact.include?(custom_field["_id"]) }

      if contact_field.present? && contact_field[:value].present?
        establishment.contacts.create!(
          description: contact_field[:value],
          first_name: "Prénom",
          last_name: "Nom"
        )
      end

      if save_tracking(establishment_tracking, siret, card[:title])
        puts "completed Establishment tracking with id #{establishment_tracking.id}" \
             "created for card: #{card[:title]} (SIRET: #{siret})."
        return establishment_tracking
      else
        puts "Failed to save completed tracking for card: #{card[:title]} (SIRET: #{siret})."
        return nil
      end
    end

    if wekan_status == "Suivi en cours" && !card[:archived]

      puts "Processing siret #{siret} Wekan status is #{wekan_status} and card is not archived."

      existing_tracking = establishment.establishment_trackings.where(state: %w[in_progress under_surveillance]).first

      if existing_tracking
        puts "Processing siret #{siret}, existing in rails"

        mongo_participants = users.find({ _id: { "$in": card[:members] } }).to_a.pluck(:username)
        new_participants = User.where(email: mongo_participants).to_a
        existing_tracking.participants |= new_participants

        mongo_referents = users.find({ _id: { "$in": card[:assignees] } }).to_a.pluck(:username)
        new_referents = User.where(email: mongo_referents).to_a
        existing_tracking.referents |= new_referents # Fusionner les référents sans doublons

        # Contact details
        id_of_contact = Set.new(custom_fields.find({ "name" => "Contact" }).to_a.pluck("_id"))
        contact_field = card[:customFields].find { |custom_field| id_of_contact.include?(custom_field["_id"]) }

        if contact_field.present? && contact_field[:value].present?
          establishment.contacts.create!(
            description: contact_field[:value],
            first_name: "Prénom",
            last_name: "Nom"
          )
        end

        existing_tracking.instance_variable_set(:@skip_modified_at_update, true)

        if existing_tracking.save
          puts "Establishment tracking with id #{existing_tracking.id} updated with participants " \
               "and referents from card: #{card[:title]} (SIRET: #{siret})."
          return existing_tracking
        else
          puts "Failed to update existing tracking (SIRET: #{siret}). " \
               "Errors: #{existing_tracking.errors.full_messages.join(', ')}"
          return nil
        end
      else

        puts "Processing siret #{siret}, not existing in rails"

        new_tracking = EstablishmentTracking.new(establishment: establishment)
        new_tracking.creator = creator
        new_tracking.state = "in_progress"
        new_tracking.start_date = card[:startAt] || card[:createdAt]
        new_tracking.end_date = card[:endAt]
        new_tracking.modified_at = card[:modifiedAt]
        new_tracking.instance_variable_set(:@skip_modified_at_update, true)

        mongo_participants = users.find({ _id: { "$in": card[:members] } }).to_a.pluck(:username)
        participants = User.where(email: mongo_participants)
        new_tracking.participants = participants.empty? ? [creator] : participants

        mongo_referents = users.find({ _id: { "$in": card[:assignees] } }).to_a.pluck(:username)
        referents = User.where(email: mongo_referents)
        new_tracking.referents = referents.empty? ? [creator] : referents

        if save_tracking(new_tracking, siret, card[:title])
          puts "New in progress establishment tracking with id #{new_tracking.id}" \
               "created for card: #{card[:title]} (SIRET: #{siret})."
          return new_tracking
        else
          puts "Failed to save new in progress tracking for card: #{card[:title]} (SIRET: #{siret})."
          return nil
        end
      end
    end

    # If cards are archived in wekan, we want the with state 'completed' and discarded in rails
    return unless card[:archived]

    puts "Processing siret #{siret} Wekan status is #{wekan_status} and card is archived."

    establishment_tracking = EstablishmentTracking.new(establishment: establishment)
    establishment_tracking.state = "completed"
    establishment_tracking.creator = creator

    # Participants and Referents
    mongo_participants = users.find({ _id: { "$in": card[:members] } }).to_a.pluck(:username)
    participants = User.where(email: mongo_participants)
    establishment_tracking.participants = participants.empty? ? [creator] : participants
    mongo_referents = users.find({ _id: { "$in": card[:assignees] } }).to_a.pluck(:username)
    referents = User.where(email: mongo_referents)
    establishment_tracking.referents = referents.empty? ? [creator] : referents

    # Determine dates
    establishment_tracking.start_date = card[:startAt] || card[:createdAt]
    establishment_tracking.end_date = card[:endAt]

    establishment_tracking.modified_at = card[:modifiedAt]
    establishment_tracking.instance_variable_set(:@skip_modified_at_update, true)

    # Contact details
    id_of_contact = Set.new(custom_fields.find({ "name" => "Contact" }).to_a.pluck("_id"))
    contact_field = card[:customFields].find { |custom_field| id_of_contact.include?(custom_field["_id"]) }

    if contact_field.present? && contact_field[:value].present?
      establishment.contacts.create!(
        description: contact_field[:value],
        first_name: "Prénom",
        last_name: "Nom"
      )
    end

    if save_and_discard_tracking(establishment_tracking, siret, card[:title])
      puts "New discarded establishment tracking with id #{establishment_tracking.id}" \
           "created for card: #{card[:title]} (SIRET: #{siret})."
      establishment_tracking
    else
      puts "Failed to save new discarded tracking for card: #{card[:title]} (SIRET: #{siret})."
      nil
    end
  end

  def create_summary(card, establishment_tracking, siret) # rubocop:disable Metrics/MethodLength
    codefi_network = Network.find_by(name: "CODEFI")
    summary = Summary.find_or_initialize_by(
      establishment_tracking: establishment_tracking,
      network: codefi_network
    )
    summary.content = card[:description]

    if summary.save
      summary.update_column(:updated_at, card[:modifiedAt])
    else
      puts "Impossible de créer la synthèse #{siret} #{card[:title]}"
      puts summary.errors.full_messages
    end
  end

  def create_all_comments(card, card_comments, establishment_tracking, siret, users) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    card_comments.find({ cardId: card[:_id] }).each do |card_comment|
      comment = Comment.find_or_initialize_by(created_at: card_comment[:createdAt])
      comment.establishment_tracking = establishment_tracking
      comment.network = Network.find_by(name: "CODEFI")
      comment_creator_mongo = users.find({ _id: card_comment[:userId] }).first
      comment.user = User.find_by(email: comment_creator_mongo[:username])
      comment.content = card_comment[:text]

      if comment.save
        comment.update_column(:created_at, card_comment[:createdAt])
      else
        puts "Impossible de créer le commentaire #{siret} #{card[:title]}"
        puts comment.errors.full_messages
      end
    end
  end

  def create_all_labels(board_labels, card, establishment_tracking) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
    return unless card[:labelIds]

    card[:labelIds].each do |label_id| # rubocop:disable Metrics/BlockLength
      label_name = board_labels[label_id] # In wekan each board holds all the labels which can then be used in the cards

      if label_name.nil?
        puts "Label with ID #{label_id} not found in board_labels."
        next
      end

      case label_name
      when "tpe", "pme", "eti", "ge"
        # Map Wekan label to Rails Size model
        size_name = label_name.upcase
        size = Size.find_by(name: size_name)
        if size
          if establishment_tracking.size.nil?
            establishment_tracking.size = size
            establishment_tracking.save || log_errors(establishment_tracking, "size assignment")
          else
            puts "Size already assigned for EstablishmentTracking #{establishment_tracking.id}. Skipping #{label_name}."
          end
        else
          puts "Size not found for label: #{label_name}."
        end

      when "Niveau rouge", "Niveau orange", "Niveau vert"
        criticality = Criticality.find_by(name: label_name)

        if criticality
          if establishment_tracking.criticality.nil?
            establishment_tracking.criticality = criticality
            if establishment_tracking.save # rubocop:disable Metrics/BlockNesting
              # puts "Assigned criticality '#{criticality.name}' to EstablishmentTracking #{establishment_tracking.id}."
            else
              log_errors(establishment_tracking, "criticality assignment")
            end
          else
            puts "Criticality already assigned for EstablishmentTracking  " \
                 "#{establishment_tracking.id}. Skipping '#{label_name}'."
          end
        else
          puts "Criticality not found for label '#{label_name}'."
        end

      when "AR-PB", "CIRI"
        # Assign as a 'sytem' Tracking Label
        tracking_label = TrackingLabel.find_by(name: label_name)
        if tracking_label.save
          unless establishment_tracking.tracking_labels.include?(tracking_label)
            establishment_tracking.tracking_labels << tracking_label
          end
        else
          log_errors(tracking_label, "label creation")
        end

      when "ALERTE MRE", "ALERTE DIRE"
        label_sf_name = case label_name
                        when "ALERTE MRE" then "Alerte MRE"
                        when "ALERTE DIRE" then "Alerte DIRE"
                        end
        # Assign as a 'sytem' Tracking Label
        tracking_label = TrackingLabel.find_by(name: label_sf_name)
        if tracking_label.save
          unless establishment_tracking.tracking_labels.include?(tracking_label)
            establishment_tracking.tracking_labels << tracking_label
          end
        else
          log_errors(tracking_label, "label creation")
        end

      when "aéronautique", "agroalimentaire", "automobile", "bois", "chimie", "construction", "déchets",
        "eau", "électronique", "ferroviaire", "métallurgie", "mode", "naval", "nucléaire",
        "numérique", "papeterie", "santé", "textile", "tourisme", "défense", "autres", "hotel./restaur."
        # Assign Sectors
        sector_name = label_name == "hotel./restaur." ? "hôtel et restauration" : label_name
        sector = Sector.find_by(name: sector_name)
        if sector
          establishment_tracking.sectors << sector unless establishment_tracking.sectors.include?(sector)
        else
          puts "Sector not found for label: #{label_name}."
        end

      else
        # Create a non-system Tracking Label for unrecognized labels
        tracking_label = TrackingLabel.find_or_initialize_by(name: label_name)
        tracking_label.system = false
        if tracking_label.save
          unless establishment_tracking.tracking_labels.include?(tracking_label)
            establishment_tracking.tracking_labels << tracking_label
          end
        else
          log_errors(tracking_label, "unrecognized label creation")
        end
      end
    end
  end

  def save_and_discard_tracking(tracking, siret, title)
    if tracking.save
      tracking.discard!
    else
      log_save_error(tracking, siret, title)
    end
  end

  def save_tracking(tracking, siret, title)
    if tracking.save
      true
    else
      log_save_error(tracking, siret, title)
      false
    end
  end

  def log_save_error(tracking, siret, title)
    puts "Failed to save EstablishmentTracking for card #{title} (SIRET: #{siret})."
    puts "Errors: #{tracking.errors.full_messages.join(', ')}"
    puts "Attributes: #{tracking.attributes.inspect}"
  end

  def log_error(siret, title, error_message)
    puts "Error for card #{title} (SIRET: #{siret}): #{error_message}"
  end

  def log_errors(record, context)
    puts "Error during #{context}: #{record.errors.full_messages.join(', ')}"
  end
end

namespace :import_from_wekan do
  desc "Import data from Wekan"
  task :cards, [:board_title] => :environment do |_task, args|
    if args[:board_title].nil?
      puts "Error: You must provide a board title as an argument, e.g., rake import_from_wekan:cards['Board Title']"
      exit(1)
    end

    board_title = args[:board_title]
    puts "Launching import for board: #{board_title}"

    service = ImportEstablishmentTrackingsService.new
    service.perform(board_title)
  end
end
