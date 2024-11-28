puts "Seeding labels"

labels = ['AR-PB', 'CIRI', 'Alerte MRE', 'Alerte DIRE']

# By default, tracking labels are 'sytem' tracking labels (defined by the sf team)
labels.each do |label_name|
    label = TrackingLabel.find_or_initialize_by(name: label_name)
    label.save!
end

puts "tracking labels seeded!"

puts "Seeding sizes..."
['TPE', 'PME', 'ETI', 'GE'].each do |size_name|
  Size.find_or_create_by!(name: size_name)
end

puts "Seeding sectors..."
[
  'aéronautique', 'agroalimentaire', 'automobile', 'bois', 'chimie',
  'construction', 'déchets', 'eau', 'électronique', 'ferroviaire',
  'hôtel et restauration', 'métallurgie', 'mode', 'naval', 'nucléaire',
  'numérique', 'papeterie', 'santé', 'textile', 'tourisme', 'défense', 'autres'
].each do |sector_name|
  Sector.find_or_create_by!(name: sector_name)
end

puts "Seeding criticalities..."
['Niveau rouge', 'Niveau orange', 'Niveau vert'].each do |criticality_name|
  Criticality.find_or_create_by!(name: criticality_name)
end

puts "Seed data for sizes, sectors, and criticalities completed!"