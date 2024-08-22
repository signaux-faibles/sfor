puts "seeding geo accesses"

custom_regions = {
  "La Réunion" => %w[974],
  "Martinique" => %w[972],
  "Guadeloupe" => %w[971 977 978],
  "Outre-Mer" => %w[971 972 973 974 975 976 977 978],
  "Guyane" => %w[973],
  "Mayotte" => %w[976],
}

custom_regions.each do |region_name, department_codes|
  geo_access = GeoAccess.find_or_create_by!(name: region_name)
  departments = Department.where(code: department_codes)
  geo_access.departments = departments
end

old_regions = {
  "Alsace" => %w[67 68],
  "Aquitaine" => %w[24 33 40 47 64],
  "Auvergne" => %w[03 15 43 63],
  "Basse-Normandie" => %w[14 50 61],
  "Bourgogne" => %w[21 58 71 89],
  "Bretagne" => %w[22 29 35 56],
  "Centre" => %w[18 28 36 37 41 45],
  "Champagne-Ardenne" => %w[08 10 51 52],
  "Corse" => %w[2A 2B],
  "Franche-Comté" => %w[25 39 70 90],
  "Haute-Normandie" => %w[27 76],
  "Île-de-France" => %w[75 77 78 91 92 93 94 95],
  "Languedoc-Roussillon" => %w[11 30 34 48 66],
  "Limousin" => %w[19 23 87],
  "Lorraine" => %w[54 55 57 88],
  "Midi-Pyrénées" => %w[09 12 31 32 46 65 81 82],
  "Nord-Pas-de-Calais" => %w[59 62],
  "Pays de la Loire" => %w[44 49 53 72 85],
  "Picardie" => %w[02 60 80],
  "Poitou-Charentes" => %w[16 17 79 86],
  "Provence-Alpes-Côte d'Azur" => %w[04 05 06 13 83 84],
  "Rhône-Alpes" => %w[01 07 26 38 42 69 73 74]
}

old_regions.each do |region_name, department_codes|
  geo_access = GeoAccess.find_or_create_by!(name: region_name)
  departments = Department.where(code: department_codes)
  geo_access.departments = departments
end

new_regions = {
  "Auvergne-Rhône-Alpes" => %w[01 03 07 15 26 38 42 43 63 69 73 74],
  "Bourgogne-Franche-Comté" => %w[21 25 39 58 70 71 89 90],
  "Bretagne" => %w[22 29 35 56],
  "Centre-Val de Loire" => %w[18 28 36 37 41 45],
  "Corse" => %w[2A 2B],
  "Grand Est" => %w[08 10 51 52 54 55 57 67 68 88],
  "Hauts-de-France" => %w[02 59 60 62 80],
  "Île-de-France" => %w[75 77 78 91 92 93 94 95],
  "Normandie" => %w[14 27 50 61 76],
  "Nouvelle-Aquitaine" => %w[16 17 19 23 24 33 40 47 64 79 86 87],
  "Occitanie" => %w[09 11 12 30 31 32 34 46 48 65 66 81 82],
  "Pays de la Loire" => %w[44 49 53 72 85],
  "Provence-Alpes-Côte d'Azur" => %w[04 05 06 13 83 84]
}

new_regions.each do |region_name, department_codes|
  geo_access = GeoAccess.find_or_create_by!(name: region_name)
  departments = Department.where(code: department_codes)
  geo_access.departments = departments
end

# Créer les GeoAccess pour chaque département individuellement
departments = [
  { code: '971', name: 'Guadeloupe' },
  { code: '977', name: 'Saint-Bathelemy' },
  { code: '978', name: 'Saint-Martin' },
  { code: '972', name: 'Martinique' },
  { code: '973', name: 'Guyane' },
  { code: '974', name: 'La Réunion' },
  { code: '976', name: 'Mayotte' },
  { code: '75', name: 'Paris' },
  { code: '92', name: 'Hauts-de-Seine' },
  { code: '78', name: 'Yvelines' },
  { code: '91', name: 'Essonne' },
  { code: '93', name: 'Seine-Saint-Denis' },
  { code: '94', name: 'Val-de-Marne' },
  { code: '95', name: "Val-d'Oise" },
  { code: '28', name: 'Eure-et-Loir' },
  { code: '18', name: 'Cher' },
  { code: '41', name: 'Loir-et-Cher' },
  { code: '37', name: 'Indre-et-Loire' },
  { code: '36', name: 'Indre' },
  { code: '45', name: 'Loiret' },
  { code: '21', name: "Côte-d'Or" },
  { code: '89', name: 'Yonne' },
  { code: '58', name: 'Nièvre' },
  { code: '71', name: 'Saône-et-Loire' },
  { code: '25', name: 'Doubs' },
  { code: '70', name: 'Haute-Saône' },
  { code: '39', name: 'Jura' },
  { code: '90', name: 'Territoire de Belfort' },
  { code: '50', name: 'Manche' },
  { code: '14', name: 'Calvados' },
  { code: '61', name: 'Orne' },
  { code: '27', name: 'Eure' },
  { code: '76', name: 'Seine-Maritime' },
  { code: '59', name: 'Nord' },
  { code: '62', name: 'Pas-de-Calais' },
  { code: '80', name: 'Somme' },
  { code: '02', name: 'Aisne' },
  { code: '60', name: 'Oise' },
  { code: '67', name: 'Bas-Rhin' },
  { code: '68', name: 'Haut-Rhin' },
  { code: '54', name: 'Meurthe-et-Moselle' },
  { code: '55', name: 'Meuse' },
  { code: '57', name: 'Moselle' },
  { code: '88', name: 'Vosges' },
  { code: '52', name: 'Haute-Marne' },
  { code: '08', name: 'Ardennes' },
  { code: '51', name: 'Marne' },
  { code: '10', name: 'Aube' },
  { code: '44', name: 'Loire-Atlantique' },
  { code: '49', name: 'Maine-et-Loire' },
  { code: '53', name: 'Mayenne' },
  { code: '72', name: 'Sarthe' },
  { code: '85', name: 'Vendée' },
  { code: '22', name: "Côtes-d'Armor" },
  { code: '29', name: 'Finistère' },
  { code: '35', name: 'Ille-et-Vilaine' },
  { code: '56', name: 'Morbihan' },
  { code: '33', name: 'Gironde' },
  { code: '40', name: 'Landes' },
  { code: '47', name: 'Lot-et-Garonne' },
  { code: '64', name: 'Pyrénées-Atlantiques' },
  { code: '24', name: 'Dordogne' },
  { code: '19', name: 'Corrèze' },
  { code: '23', name: 'Creuse' },
  { code: '87', name: 'Haute-Vienne' },
  { code: '16', name: 'Charente' },
  { code: '17', name: 'Charente-Maritime' },
  { code: '79', name: 'Deux-Sèvres' },
  { code: '86', name: 'Vienne' },
  { code: '31', name: 'Haute-Garonne' },
  { code: '32', name: 'Gers' },
  { code: '46', name: 'Lot' },
  { code: '82', name: 'Tarn-et-Garonne' },
  { code: '09', name: 'Ariège' },
  { code: '11', name: 'Aude' },
  { code: '12', name: 'Aveyron' },
  { code: '30', name: 'Gard' },
  { code: '34', name: 'Hérault' },
  { code: '48', name: 'Lozère' },
  { code: '66', name: 'Pyrénées-Orientales' },
  { code: '81', name: 'Tarn' },
  { code: '07', name: 'Ardèche' },
  { code: '26', name: 'Drôme' },
  { code: '74', name: 'Haute-Savoie' },
  { code: '38', name: 'Isère' },
  { code: '73', name: 'Savoie' },
  { code: '01', name: 'Ain' },
  { code: '42', name: 'Loire' },
  { code: '69', name: 'Rhône' },
  { code: '03', name: 'Allier' },
  { code: '15', name: 'Cantal' },
  { code: '43', name: 'Haute-Loire' },
  { code: '63', name: 'Puy-de-Dôme' },
  { code: '04', name: 'Alpes-de-Haute-Provence' },
  { code: '05', name: 'Hautes-Alpes' },
  { code: '06', name: 'Alpes-Maritimes' },
  { code: '13', name: 'Bouches-du-Rhône' },
  { code: '83', name: 'Var' },
  { code: '84', name: 'Vaucluse' },
  { code: '2A', name: 'Corse-du-Sud' },
  { code: '2B', name: 'Haute-Corse' },
  { code: '77', name: 'Seine-et-Marne' },
  { code: '65', name: 'Hautes-Pyrénées' }
]

departments.each do |department|
  geo_access = GeoAccess.find_or_create_by!(name: department[:code])
  geo_access.departments = [Department.find_by(code: department[:code])]
end

geo_access_france = GeoAccess.find_or_create_by!(name: 'France entière')
geo_access_france.departments = Department.all

puts "GeoAccess and their associated departments seeded"