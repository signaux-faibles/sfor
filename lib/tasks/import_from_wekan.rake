# lib/tasks/import_from_wekan.rake
# Import data from wekan mongo db
# usage : rake import_from_wekan:users

require 'mongo'

def create_company(card, department, siren, siret)
  company = Company.find_or_initialize_by(siren: siren)
  company.siren = siren
  company.siret = siret
  company.department = department
  unless company.save
    puts "Impossible de créer l'entreprise #{siren} #{card[:title]}"
  end
  company
end

def create_establishment(card, company, department, siren, siret)
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

def create_establishment_tracking(card, creator, establishment, lists, siret, users, custom_fields)
  establishment_tracking = EstablishmentTracking.find_or_initialize_by(establishment: establishment)
  establishment_tracking.establishment = establishment
  establishment_tracking.creator = creator
  mongo_participants = users.find({ "_id": { "$in": card[:members] } }).to_a.map { |user| user[:username] }
  participants = User.where(email: mongo_participants)
  establishment_tracking.participants = participants.empty? ? [creator] : participants
  mongo_referents = users.find({ "_id": { "$in": card[:assignees] } }).to_a.map { |user| user[:username] }
  referents = User.where(email: mongo_referents)
  establishment_tracking.referents = referents.empty? ? [creator] : referents
  establishment_tracking.start_date = card[:startAt] || card[:createdAt]
  establishment_tracking.end_date = card[:endAt]
  mongo_status = lists.find("_id": card[:listId]).first[:title]
  if (card[:archived] or mongo_status == "Suivi terminé")
    establishment_tracking.state = "completed"
  elsif (mongo_status == "A définir" or mongo_status == "Suivi en cours")
    establishment_tracking.state = "in_progress"
  elsif (mongo_status == "Veille")
    establishment_tracking.state = "under_surveillance"
  else
    puts "Colonne inconnue : #{mongo_status}"
  end
  # save contact
  id_of_contact = Set.new(custom_fields.find({ "name" => "Contact" }).to_a.map { |pair| pair["_id"] })
  if card[:customFields].find { |customField| id_of_contact.include?(customField["_id"]) }
    establishment_tracking.contact = card[:customFields].find { |customField| id_of_contact.include?(customField["_id"]) }[:value]
  end

  if establishment_tracking.save
    begin
      establishment_tracking.discard!
    rescue Discard::RecordNotDiscarded => e
      if establishment_tracking.discarded?
        # puts "Accompagnement is already discarded: #{card[:siret]}"
      else
        puts "Failed to discard accompagnement: #{card[:siret]}. Error: #{e.message}"
      end
    end
    # puts "    Création de la fiche d'établissement pour #{siret} #{card[:title]}"
  else
    puts "Impossible de créer la fiche pour #{siret} #{card[:title]}"
    puts "Participants: #{establishment_tracking.participants.to_a}}"
    puts establishment_tracking.errors.full_messages
  end
  establishment_tracking
end

def create_summary(card, establishment_tracking, siret)
  summary = Summary.find_or_initialize_by(establishment_tracking: establishment_tracking)
  summary.content = card[:description]
  summary.network = Network.find_by(name: "CRP")

  if summary.save
    summary.update_column(:updated_at, card[:modifiedAt])
  else
    puts "Impossible de créer la synthèse #{siret} #{card[:title]}"
    puts summary.errors.full_messages
  end
end

def create_all_comments(card, card_comments, establishment_tracking, siret, users)
  card_comments.find({ cardId: card[:_id] }).each do |card_comment|
    comment = Comment.find_or_initialize_by(created_at: card_comment[:createdAt])
    comment.establishment_tracking = establishment_tracking
    comment.network = Network.find_by(name: "CRP")
    comment_creator_mongo = users.find({ "_id": card_comment[:userId] }).first
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

def create_all_labels(board_label, card, establishment_tracking)
  if card[:labelIds]
    card[:labelIds].each do |label_id|
      if board_label[label_id]
        tracking_label = TrackingLabel.find_or_initialize_by(name: board_label[label_id])
        tracking_label.name = board_label[label_id]
        tracking_label.system = false
        establishment_tracking.tracking_labels << tracking_label
        unless tracking_label.save
          puts "error creating tracking_label #{tracking_label.full_messages}"
        end

        unless establishment_tracking.save
          puts "error creating establishment_tracking #{establishment_tracking.full_messages}"
        end
      end
    end
  end
end

namespace :import_from_wekan do
  desc "Import cards from Wekan and create corresponding Rails models"
  task cards: :environment do
    mongo_host = ENV['MONGO_DB_HOST'] || '10.2.0.231'
    mongo_port = ENV['MONGO_DB_PORT'] || '27017'
    mongo_db_name = ENV['MONGO_DB_NAME'] || 'test'
    mongo_user = ENV['MONGO_DB_USER'] || 'wekan.racine'
    mongo_password = ENV['MONGO_DB_PASSWORD'] || 'XXX'

    client = Mongo::Client.new(["#{mongo_host}:#{mongo_port}"], database: mongo_db_name, user: mongo_user, password: mongo_password, auth_source: 'admin')

    boards = client[:boards]
    swimlanes = client[:swimlanes]
    cards = client[:cards]
    users = client[:users]
    lists = client[:lists]
    card_comments = client[:card_comments]
    custom_fields = client[:customFields]

    sf_siret_regex = /(\d{14})/
    extract_department_from_swimlane_title_regex = /(\d+[A|B]?) \(.*\)/

    # boards_ids = boards.find({ title: { "$regex": '^Tableau CRP HDF' } }).to_a.map { |board| board[:_id]}
    boards_ids = boards.find({ title: { "$regex": '^Tableau CRP' } }).to_a.map { |board| board[:_id] }

    unique_emails = Set.new

    swimlanes.find({ boardId: { "$in": boards_ids } }).sort(title: 1).each do |swimlane|
      puts swimlane[:title]
      board_label = boards.find(_id: swimlane[:boardId]).first[:labels].map { |obj| [obj["_id"], obj["name"]] }.to_h
      department_string = swimlane[:title].match(extract_department_from_swimlane_title_regex)[1]
      department = Department.find_by(code: department_string)
      cards.find({ swimlaneId: swimlane[:_id] }).each do |card|
        custom_field_siret = card[:customFields].find { |customField| customField["value"] =~ sf_siret_regex }&.dig(:value)

        if custom_field_siret&.match(sf_siret_regex)
          siret = custom_field_siret&.match(sf_siret_regex)[1]
          siren = siret[0, 9]

          company = create_company(card, department, siren, siret)

          establishment = create_establishment(card, company, department, siren, siret)

          mongo_creator = users.find({ "_id": card[:userId] }).first
          creator = User.find_by(email: mongo_creator[:username])

          if creator
            establishment_tracking = create_establishment_tracking(card, creator, establishment, lists, siret, users, custom_fields)
            create_summary(card, establishment_tracking, siret)

            create_all_comments(card, card_comments, establishment_tracking, siret, users)
            create_all_labels(board_label, card, establishment_tracking)
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

    client.close

    puts "Wekan crp cards import completed!"
  end
end

