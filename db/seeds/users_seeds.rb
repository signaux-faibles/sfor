require 'faker'

puts "Creating users..."

sf_entity = Entity.create!(name: 'SIGNAUX FAIBLES')
dreets_entity = Entity.create!(name: 'DREETS')

sf_segment = Segment.create!(name: 'sf')
dreets_segment = Segment.create!(name: 'crp')

geo_access = GeoAccess.find_by(name: 'France entière')


User.create!(email: 'charles.marcoin@beta.gouv.fr',
             password: 'password',
             password_confirmation: 'password',
             first_name: 'Charles',
             last_name: 'Marcoin',
             entity: sf_entity,
             segment: sf_segment,
             geo_access: geo_access)

19.times do
  User.create!(
    email: Faker::Internet.unique.email,
    password: 'password',
    password_confirmation: 'password',
    first_name: Faker::Name.first_name,
    last_name: Faker::Name.last_name,
    entity: dreets_entity,
    segment: dreets_segment,
    geo_access: geo_access
  )
end

puts "Users seeded"