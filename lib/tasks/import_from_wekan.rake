# lib/tasks/import_from_wekan.rake
# Import data from wekan mongo db
# usage : rake import_from_wekan:users

require 'mongo'

namespace :import_from_wekan do
  desc "Import user data from wekan (MongoDB) to rails users table (PostgreSQL)"
  #TODO Do we really need this ? We can import users from the habilitations file
  task users: :environment do
    mongo_host = ENV['MONGO_DB_HOST'] || 'wekan-db' # The name of the wekan db podman container in local dev mode
    mongo_port = ENV['MONGO_DB_PORT'] || '27017'
    mongo_db_name = ENV['MONGO_DB_NAME'] || 'test'

    client = Mongo::Client.new([ "#{mongo_host}:#{mongo_port}" ], database: mongo_db_name)
    mongo_collection = client[:users]

    # Loop through each user document in the wekan MongoDB collection
    mongo_collection.find.each do |document|

      # Looks like the uid in keycloak is the user email
      email = document.dig('services', 'oidc', 'id')
      next unless email

      full_name = document.dig('profile', 'fullname') || ''
      first_name, last_name = full_name.split(' ', 2)
      first_name ||= ''
      last_name ||= ''

      # Find or initialize a PostgreSQL user by email
      user = User.find_or_initialize_by(email: email)
      user.provider = 'oidc'
      user.email = document.dig('services', 'oidc', 'id')
      user.first_name = first_name
      user.last_name = last_name

      # Store the MongoDB _id to then link companies and users through establishment_follower in another rake task
      user.wekan_document_id = document['_id'].to_s

      user.password = Devise.friendly_token[0, 20] if user.new_record?

      if user.save
        puts "Imported wekan user: #{user.email}"
      else
        puts "Failed to import wekan user: #{user.email} - #{user.errors.full_messages.join(', ')}"
      end
    end

    puts "Wekan data import completed."
  end

  namespace :import_from_wekan do
    desc "Import cards from Wekan and create corresponding Rails models"
    task cards: :environment do
      mongo_host = ENV['MONGO_DB_HOST'] || 'wekan-db'
      mongo_port = ENV['MONGO_DB_PORT'] || '27017'
      mongo_db_name = ENV['MONGO_DB_NAME'] || 'test'

      client = Mongo::Client.new(["#{mongo_host}:#{mongo_port}"], database: mongo_db_name)

      boards = client[:boards]
      swimlanes = client[:swimlanes]
      cards = client[:cards]

      #TODO target the boards we want based on their names (have to include 'crp')
      target_boards = boards.find({ name: { "$in": ['Board 1', 'Board 2'] } })
      target_swimlanes = swimlanes.find({ boardId: { "$in": target_boards.map { |board| board['_id'] } } })

      # Iterate over each swimlane (a swimlane seems to be a department) and its cards
      target_swimlanes.each do |swimlane|
        puts "Processing swimlane: #{swimlane['title']}"

        swimlane_cards = cards.find({ swimlaneId: swimlane['_id'] })

        # TODO Determine how to work on columns and do the mapping between the columns names and the EstablishmentTracking state machine statuses
        swimlane_cards.each do |card|
          # Print the card's details (or perform operations with the card)
          puts "Processing card: #{card['title']}"

          # Here we will create the Establishment, EstablishmentTracking, Summary, Comment, etc.

          # Creating an Establishment skeleton
          establishment = Establishment.find_or_create_by(siret: card['customField_siret']) do |e|
            e.raison_sociale = card['title']
            e.department = Department.find_by(code: card['customField_department'])
          end

          # Creating an EstablishmentTracking skeleton
          tracking = EstablishmentTracking.find_or_create_by(establishment: establishment) do |t|
            t.creator = User.first #TODO : determine how to retrieve the user
            t.start_date = Date.today
            t.status = 'active'
          end

          # Creating a Summary skeleton
          summary = Summary.create!(
            content: card['description'],
            establishment_tracking: tracking,
            is_codefi: false #CODEFI is false because we are only importing crp cards
          )

          # Creating a Comment skeleton
          comment = Comment.create!(
            content: card['comment'],
            establishment_tracking: tracking,
            user: User.first #TODO : determine how to retrieve the user
          )

          # Creating Labels skeleton
          tracking_label = TrackingLabel.find_or_create_by(name: card['customField_label'])
          EstablishmentTrackingLabel.create!(establishment_tracking: tracking, tracking_label: tracking_label)
        end
      end

      client.close

      puts "Wekan crp cards import completed!"
    end
  end


end
