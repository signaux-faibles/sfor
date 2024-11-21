require 'faker'

puts "Creating networks..."

sf_network = Network.create!(name: 'Signaux Faibles')
crp_network = Network.create!(name: 'CRP')
codefi_network = Network.create!(name: 'CODEFI')

puts "Creating entities..."

sf_entity = Entity.create!(name: 'SIGNAUX FAIBLES')
crp_entity = Entity.create!(name: 'DREETS')

puts "Creating segments..."

sf_segment = Segment.create!(name: 'sf', network: sf_network)
crp_segment = Segment.create!(name: 'crp', network: crp_network)
dreets_reseaucrp_segment = Segment.create!(name: 'dreets_reseaucrp', network: crp_network)

puts "Creating geo_accesses..."

geo_access = GeoAccess.find_by(name: 'France entière')

puts "Creating users..."

charles = User.new(
  email: 'charles.marcoin@beta.gouv.fr',
  password: 'password',
  password_confirmation: 'password',
  first_name: 'Charles',
  last_name: 'Marcoin',
  entity: sf_entity,
  segment: sf_segment,
  geo_access: geo_access
)

josquin = User.new(
  email: 'josquin.cornec@beta.gouv.fr',
  password: 'password',
  password_confirmation: 'password',
  first_name: 'Josquin',
  last_name: 'Cornec',
  entity: sf_entity,
  segment: sf_segment,
  geo_access: geo_access
)

[charles, josquin].each do |user|

  user.networks = [codefi_network, sf_network] # Assign both networks at once
  user.save
end

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

puts "Networks, segments, geo accesses and users seeded"