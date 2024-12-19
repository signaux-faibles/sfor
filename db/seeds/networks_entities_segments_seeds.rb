puts "Creating networks..."

sf_network = Network.create!(name: 'Signaux Faibles')
crp_network = Network.create!(name: 'CRP')
Network.create!(name: 'CODEFI')

puts "Creating entities..."

Entity.create!(name: 'SIGNAUX FAIBLES')
Entity.create!(name: 'DREETS')

puts "Creating segments..."

Segment.create!(name: 'sf', network: sf_network)
Segment.create!(name: 'crp', network: crp_network)
Segment.create!(name: 'dreets_reseaucrp', network: crp_network)
