sf_network = Network.find_by(name: 'Signaux Faibles')
crp_network = Network.find_by(name: 'CRP')
codefi_network = Network.find_by(name: 'CODEFI')

puts "Creating entities..."

sf_entity = Entity.find_by(name: 'SIGNAUX FAIBLES')

puts "Creating segments..."

sf_segment = Segment.find_by(name: 'sf', network: sf_network)


puts "Creating geo_accesses..."

geo_access = GeoAccess.find_by(name: 'France entière')



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

anna = User.new(
  email: 'anna.ouhayoun@beta.gouv.fr',
  password: 'password',
  password_confirmation: 'password',
  first_name: 'Anna',
  last_name: 'Ouhayoun',
  entity: sf_entity,
  segment: sf_segment,
  geo_access: geo_access
)

loic = User.new(
  email: 'loic.poillion@dgfip.finances.gouv.fr',
  password: 'password',
  password_confirmation: 'password',
  first_name: 'Loïc',
  last_name: 'Poillon',
  entity: sf_entity,
  segment: sf_segment,
  geo_access: geo_access
)

esther = User.new(
  email: 'esther.spindler@beta.gouv.fr',
  password: 'password',
  password_confirmation: 'password',
  first_name: 'Esther',
  last_name: 'Spindler',
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

[charles, josquin, anna, esther, loic].each do |user|

  user.networks = [codefi_network, sf_network] # Assign both networks at once
  user.save
end