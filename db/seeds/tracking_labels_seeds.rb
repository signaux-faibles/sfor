puts "Seeding tracking labels"

labels = ['pme', 'Alerte DIRE/MRE', 'Alerte MRE',
          'Alerte DIRE', 'Exposition RUS/UKR',
          'AR-PB', 'Repreneur', 'signaux-faibles',
          'Signalé MAA', 'CVAP', 'CODEFI', 'CIRI',
          'sensible', 'tension sociale', 'Surendettement PGE',
          'approvisionnement', 'énergie', 'cas par cas énergie',
          'déchets', 'eau', 'automobile', 'aéronautique', 'agroalimentaire',
          'bois', 'chimie', 'construction', 'électronique', 'métallurgie', 'mode',
          'naval', 'nucléaire', 'numérique', 'santé', 'papeterie', 'tourisme', 'hotel./restaur',
          'textile', 'défense', 'tpe', 'pme', 'ge', 'eti'
]

labels.each do |label_name|
  TrackingLabel.find_or_create_by(name: label_name)
end

puts "Tracking labels seeded!"