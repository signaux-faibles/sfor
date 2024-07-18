# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

require 'faker'

require_relative 'seeds/roles_seeds'
require_relative 'seeds/departments_seeds'
require_relative 'seeds/users_seeds'
require_relative 'seeds/campaigns_seeds'
require_relative 'seeds/lists_seeds'
require_relative 'seeds/activity_sectors_seeds'
require_relative 'seeds/establishments_seeds'
require_relative 'seeds/trackings_seeds'

puts "Database seeded"