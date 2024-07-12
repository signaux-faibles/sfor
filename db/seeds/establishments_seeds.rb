# Create establishments and companies (parent establishments)
10.times do
  department = Department.order('RANDOM()').first
  siren = Faker::Number.unique.number(digits: 9).to_s
  siret = "#{siren}#{Faker::Number.number(digits: 5)}"

  company = Establishment.create!(
    department: department,
    raison_sociale: Faker::Company.name,
    siren: siren,
    siret: siret,
    commune: Faker::Address.city,
    libelle_departement: Faker::Address.state,
    code_departement: Faker::Address.zip_code,
    valeur_score: Faker::Number.decimal(l_digits: 2),
    detail_score: { example: "data" }, # Replace with actual JSON structure if needed
    first_alert: Faker::Boolean.boolean,
    first_list_entreprise: Faker::Lorem.word,
    first_red_list_entreprise: Faker::Lorem.word,
    first_list_etablissement: Faker::Lorem.word,
    first_red_list_etablissement: Faker::Lorem.word,
    last_list: Faker::Lorem.word,
    last_alert: Faker::Lorem.word,
    liste: Faker::Lorem.word,
    chiffre_affaire: Faker::Number.decimal(l_digits: 2),
    prev_chiffre_affaire: Faker::Number.decimal(l_digits: 2),
    arrete_bilan: Faker::Date.backward(days: 365),
    exercice_diane: Faker::Number.between(from: 1, to: 10),
    variation_ca: Faker::Number.decimal(l_digits: 2),
    resultat_expl: Faker::Number.decimal(l_digits: 2),
    prev_resultat_expl: Faker::Number.decimal(l_digits: 2),
    excedent_brut_d_exploitation: Faker::Number.decimal(l_digits: 2),
    prev_excedent_brut_d_exploitation: Faker::Number.decimal(l_digits: 2),
    effectif: Faker::Number.between(from: 1, to: 100),
    effectif_entreprise: Faker::Number.between(from: 1, to: 100),
    date_entreprise: Faker::Date.backward(days: 365),
    date_effectif: Faker::Date.backward(days: 365),
    libelle_n5: Faker::Lorem.word,
    libelle_n1: Faker::Lorem.word,
    code_activite: Faker::Lorem.word,
    last_procol: Faker::Lorem.word,
    date_last_procol: Faker::Date.backward(days: 365),
    activite_partielle: Faker::Boolean.boolean,
    apconso_heure_consomme: Faker::Number.number(digits: 3),
    apconso_montant: Faker::Number.number(digits: 5),
    hausse_urssaf: Faker::Boolean.boolean,
    dette_urssaf: Faker::Number.decimal(l_digits: 2),
    periode_urssaf: Faker::Date.backward(days: 365),
    presence_part_salariale: Faker::Boolean.boolean,
    alert: Faker::Lorem.word,
    raison_sociale_groupe: Faker::Company.name,
    territoire_industrie: Faker::Boolean.boolean,
    code_territoire_industrie: Faker::Lorem.word,
    libelle_territoire_industrie: Faker::Lorem.word,
    statut_juridique_n3: Faker::Lorem.word,
    statut_juridique_n2: Faker::Lorem.word,
    statut_juridique_n1: Faker::Lorem.word,
    date_ouverture_etablissement: Faker::Date.backward(days: 365),
    date_creation_entreprise: Faker::Date.backward(days: 365),
    secteur_covid: Faker::Lorem.word,
    etat_administratif: Faker::Lorem.word,
    etat_administratif_entreprise: Faker::Lorem.word,
    has_delai: Faker::Boolean.boolean
  )

  # Create establishments for each company
  5.times do
    department = Department.order('RANDOM()').first

    Establishment.create!(
      department: department,
      raison_sociale: Faker::Company.name,
      siret: "#{company.siren}#{Faker::Number.number(digits: 5)}",
      siren: siren,
      commune: Faker::Address.city,
      libelle_departement: Faker::Address.state,
      code_departement: Faker::Address.zip_code,
      valeur_score: Faker::Number.decimal(l_digits: 2),
      detail_score: { example: "data" },
      first_alert: Faker::Boolean.boolean,
      first_list_entreprise: Faker::Lorem.word,
      first_red_list_entreprise: Faker::Lorem.word,
      first_list_etablissement: Faker::Lorem.word,
      first_red_list_etablissement: Faker::Lorem.word,
      last_list: Faker::Lorem.word,
      last_alert: Faker::Lorem.word,
      liste: Faker::Lorem.word,
      chiffre_affaire: Faker::Number.decimal(l_digits: 2),
      prev_chiffre_affaire: Faker::Number.decimal(l_digits: 2),
      arrete_bilan: Faker::Date.backward(days: 365),
      exercice_diane: Faker::Number.between(from: 1, to: 10),
      variation_ca: Faker::Number.decimal(l_digits: 2),
      resultat_expl: Faker::Number.decimal(l_digits: 2),
      excedent_brut_d_exploitation: Faker::Number.decimal(l_digits: 2),
      prev_excedent_brut_d_exploitation: Faker::Number.decimal(l_digits: 2),
      effectif: Faker::Number.between(from: 1, to: 100),
      effectif_entreprise: Faker::Number.between(from: 1, to: 100),
      date_entreprise: Faker::Date.backward(days: 365),
      date_effectif: Faker::Date.backward(days: 365),
      libelle_n5: Faker::Lorem.word,
      libelle_n1: Faker::Lorem.word,
      code_activite: Faker::Lorem.word,
      last_procol: Faker::Lorem.word,
      date_last_procol: Faker::Date.backward(days: 365),
      activite_partielle: Faker::Boolean.boolean,
      apconso_heure_consomme: Faker::Number.number(digits: 3),
      apconso_montant: Faker::Number.number(digits: 5),
      hausse_urssaf: Faker::Boolean.boolean,
      dette_urssaf: Faker::Number.decimal(l_digits: 2),
      periode_urssaf: Faker::Date.backward(days: 365),
      presence_part_salariale: Faker::Boolean.boolean,
      alert: Faker::Lorem.word,
      raison_sociale_groupe: Faker::Company.name,
      territoire_industrie: Faker::Boolean.boolean,
      code_territoire_industrie: Faker::Lorem.word,
      libelle_territoire_industrie: Faker::Lorem.word,
      statut_juridique_n3: Faker::Lorem.word,
      statut_juridique_n2: Faker::Lorem.word,
      statut_juridique_n1: Faker::Lorem.word,
      date_ouverture_etablissement: Faker::Date.backward(days: 365),
      date_creation_entreprise: Faker::Date.backward(days: 365),
      secteur_covid: Faker::Lorem.word,
      etat_administratif: Faker::Lorem.word,
      etat_administratif_entreprise: Faker::Lorem.word,
      has_delai: Faker::Boolean.boolean,
      parent_company_id: company.id
    )
  end
end


# Assign companies to campaigns
campaigns = Campaign.all
establishments = Establishment.all.sample((0.8 * Establishment.count).round)

establishments.each do |establishment|
  CampaignMembership.create!(
    campaign: campaigns.sample,
    establishment: establishment
  )
end