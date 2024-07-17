require 'csv'

puts "Seeding Activity Sectors..."

csv_file_path = Rails.root.join('db', 'seeds', 'naf_codes.csv')

CSV.foreach(csv_file_path, headers: true) do |row|
  ActivitySector.create!(
    id: row['id'],
    depth: row['niveau'],
    code: row['code'],
    libelle: row['libelle'],
    parent_id: row['id_parent'],
    level_one_id: row['id_n1']
  )
end

puts "Activity Sectors seeded"
