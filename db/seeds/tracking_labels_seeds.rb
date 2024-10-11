puts "Seeding label groups and tracking labels"

filiere_group = LabelGroup.find_or_create_by(name: 'Filière')
taille_entreprises_group = LabelGroup.find_or_create_by(name: "Taille d'entreprises")
niveau_priorite_group = LabelGroup.find_or_create_by(name: 'Niveau de priorité')

labels = {
  filiere_group => [
    'approvisionnement', 'énergie', 'cas par cas énergie',
    'déchets', 'eau', 'automobile', 'aéronautique', 'agroalimentaire',
    'bois', 'chimie', 'construction', 'électronique', 'métallurgie', 'mode',
    'naval', 'nucléaire', 'numérique', 'santé', 'papeterie', 'tourisme', 'hotel./restaur',
    'textile', 'défense'
  ],
  taille_entreprises_group => %w[tpe pme ge eti],
  niveau_priorite_group => [
    'Alerte DIRE/MRE', 'Alerte MRE', 'Alerte DIRE', 'AR-PB', 'Repreneur',
    'signaux-faibles', 'Signalé MAA', 'CVAP', 'CODEFI', 'CIRI',
    'sensible', 'tension sociale', 'Surendettement PGE', 'Exposition RUS/UKR'
  ]
}

labels.each do |group, label_names|
  label_names.each do |label_name|
    label = TrackingLabel.find_or_initialize_by(name: label_name)
    label.label_group = group
    label.save!
  end
end

puts "Label groups and tracking labels seeded!"