# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

require 'faker'

require_relative 'seeds/actions_seeds'
require_relative 'seeds/departments_seeds'
require_relative 'seeds/geo_accesses_seed'
require_relative 'seeds/networks_entities_segments_seeds'
require_relative 'seeds/labels_and_tracking_metadata_seeds'

unless Rails.env.production?
  require_relative 'seeds/activity_sectors_seeds'
  require_relative 'seeds/establishments_seeds'
  require_relative 'seeds/users_seeds'
  require_relative 'seeds/trackings_seeds'
  
  # Test establishments for OSF sync testing (only in development)
  if Rails.env.development? && ENV['CREATE_TEST_ESTABLISHMENTS'] == 'true'
    require_relative 'seeds/test_establishments_seeds'
  end
end

puts "Database seeded"