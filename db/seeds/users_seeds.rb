require 'faker'

puts "Creating users..."

User.create!(email: 'charles.marcoin@gmail.com', password: 'password',
             password_confirmation: 'password', first_name: 'Charles', last_name: 'Marcoin')

19.times do
  User.create!(
    email: Faker::Internet.unique.email,
    password: 'password',
    password_confirmation: 'password',
    first_name: Faker::Name.first_name,
    last_name: Faker::Name.last_name
  )
end

puts "Users seeded"