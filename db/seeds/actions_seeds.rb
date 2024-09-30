puts "Seeding actions"

actions = [
  'Soutien financier public',
  'Échanges avec les créanciers',
  'Médiation avec les partenaires',
  'Appui à une politique d’emploi',
  'Prise en charge judiciaire',
  'Recherche et suivi de repreneur',
  'Repositionnements et restructurations',
  'Appui à l’installation et gestion immobilière',
  'Soutien à la croissance et filière',
  'Coaching, soutien psychologique'
]

actions.each do |action_name|
  Action.find_or_create_by(name: action_name)
end

puts "Actions seeded!"