# db/seeds/campaigns_seeds.rb

three_months_ago = Date.today - 3.months
yesterday = Date.today - 1.day
three_months_later = Date.today + 3.months

Campaign.create!([
   {
     name: "#{three_months_ago.strftime('%B %Y')}",
     start_date: three_months_ago,
     end_date: yesterday,
   },
   {
     name: "#{Date.today.strftime('%B %Y')}",
     start_date: Date.today,
     end_date: three_months_later
   },
 ])

puts "Campaigns seeded"