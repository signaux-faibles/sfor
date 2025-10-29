puts "Creating companies and establishments"

departments = Department.all

10.times do
  department = departments.sample
  raison_sociale = Faker::Company.name
  siren = Faker::Number.unique.number(digits: 9).to_s
  siret = "#{siren}#{Faker::Number.number(digits: 5)}"
  creation = Faker::Date.between(from: 10.years.ago, to: Date.current)
  statut_juridique = Faker::Number.number(digits: 4).to_s

  Company.create!(
    siren: siren,
    raison_sociale: raison_sociale,
    creation: creation,
    statut_juridique: statut_juridique
  )

  Establishment.create!(
    departement: department.code,
    siren: siren,
    siret: siret,
    commune: Faker::Address.city,
    siege: true
  )

  # Create additional establishments for the company
  rand(1..5).times do
    department = departments.sample
    new_siret = "#{siren}#{Faker::Number.unique.number(digits: 5)}"
    Establishment.create!(
      departement: department.code,
      siret: new_siret,
      siren: siren,
      commune: Faker::Address.city,
      siege: false
    )
  end
end

puts "Done creating companies and establishments"

=begin
puts "Assigning Companies to Campaigns..."

campaigns = Campaign.all
companies = Company.all.sample((0.8 * Establishment.count).round)

companies.each do |company|
  CampaignCompany.create!(
    campaign: campaigns.sample,
    company:,
    status: 'pending'
  )
end

puts "Companies assigned to Campaigns."

puts "Assigning Companies to Lists..."

lists = List.all
companies = Company.all

lists.each do |list|
  companies.sample((companies.count * 0.9).round).each do |company|
    CompanyList.create!(company: company, list: list)
  end
end

puts "Companies assigned to Lists."
=end




