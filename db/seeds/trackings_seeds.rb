puts "Creating establishment_trackings..."

users = User.all
establishments = Establishment.all

establishments.each do |establishment|
  if rand < 0.3
    number_of_trackings = rand < 0.5 ? 1 : rand(2..3)
    number_of_trackings.times do
      creator = users.sample
      tracking = EstablishmentTracking.create!(
        creator: creator,
        establishment: establishment,
        start_date: Faker::Date.backward(days: 365),
        end_date: Faker::Date.forward(days: 365),
        status: ['active', 'inactive'].sample
      )

      participants = users.sample(rand(1..10))
      referents = users.sample(rand(1..2))

      referents << creator unless referents.include?(creator)

      participants.each do |participant|
        TrackingParticipant.create!(user: participant, establishment_tracking: tracking)
      end

      referents.each do |referent|
        TrackingReferent.create!(user: referent, establishment_tracking: tracking)
      end
    end
  end
end

puts "Trackings created."