require 'faker'

puts "Creating users..."
codefi_network = Network.create!(name: 'CODEFI')

crp_entity = Entity.find_by(name: 'DREETS')

crp_segment = Segment.find_by(name: 'crp', network: crp_network)
dreets_reseaucrp_segment = Segment.find_by(name: 'dreets_reseaucrp', network: crp_network)

19.times do
  user = User.new(
    email: Faker::Internet.unique.email,
    password: 'password',
    password_confirmation: 'password',
    first_name: Faker::Name.first_name,
    last_name: Faker::Name.last_name,
    entity: crp_entity,
    segment: [crp_segment, dreets_reseaucrp_segment].sample, # Randomly assign segment
    geo_access: geo_access
  )

  user.networks = [codefi_network, crp_network] # Assign both networks at once

  user.save
end

puts "Users seeded"