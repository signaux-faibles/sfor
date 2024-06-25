# lib/tasks/import_from_wekan.rake
# Import data from wekan mongo db
# usage : rake import_from_wekan:users

require 'mongo'

namespace :import_from_wekan do
  desc "Import user data from wekan (MongoDB) to rails users table (PostgreSQL)"
  task users: :environment do
    # MongoDB connection setup
    mongo_host = ENV['MONGO_DB_HOST'] || 'wekandb' # The name of the wekan db podman service in local dev mode
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
end
