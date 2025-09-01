# Test establishments rake tasks for OSF sync testing

namespace :test do # rubocop:disable Metrics/BlockLength
  desc "Create test establishments for OSF sync testing (DEVELOPMENT ONLY)"
  task :create_establishments, [:count] => :environment do |_t, args|
    unless Rails.env.development?
      puts "❌ This task can only be run in development environment"
      exit 1
    end

    count = args[:count]&.to_i || 10_000

    puts "🚀 Creating #{count} test establishments for OSF sync testing..."

    # Set environment variable and load the seed
    ENV["TEST_ESTABLISHMENTS_COUNT"] = count.to_s
    ENV["CREATE_TEST_ESTABLISHMENTS"] = "true"

    load Rails.root.join("db", "seeds", "test_establishments_seeds.rb")
  end

  desc "Remove all test establishments (DEVELOPMENT ONLY)"
  task clear_establishments: :environment do
    unless Rails.env.development?
      puts "❌ This task can only be run in development environment"
      exit 1
    end

    puts "🧹 Clearing all test establishments..."

    test_establishments = Establishment.where("siren LIKE '000000%'")
    test_companies = Company.where("siren LIKE '000000%'")

    puts "   Deleting #{test_establishments.count} test establishments..."
    test_establishments.delete_all

    puts "   Deleting #{test_companies.count} test companies..."
    test_companies.delete_all

    puts "✅ Test data cleared!"
  end

  desc "Remove test establishments created today (DEVELOPMENT ONLY)"
  task clear_today_establishments: :environment do
    unless Rails.env.development?
      puts "❌ This task can only be run in development environment"
      exit 1
    end

    today_start = Date.current.beginning_of_day
    today_end = Date.current.end_of_day

    puts "🧹 Clearing test establishments created today (#{Date.current})..."

    test_establishments_today = Establishment.where(
      "siren LIKE '000000%' AND created_at BETWEEN ? AND ?",
      today_start,
      today_end
    )

    test_companies_today = Company.where(
      "siren LIKE '000000%' AND created_at BETWEEN ? AND ?",
      today_start,
      today_end
    )

    puts "   Deleting #{test_establishments_today.count} test establishments created today..."
    test_establishments_today.delete_all

    puts "   Deleting #{test_companies_today.count} test companies created today..."
    test_companies_today.delete_all

    puts "✅ Today's test data cleared!"
  end

  desc "Show test establishments statistics"
  task show_stats: :environment do
    test_companies = Company.where("siren LIKE '000000%'")
    test_establishments = Establishment.where("siren LIKE '000000%'")

    if test_establishments.empty?
      puts "📊 No test establishments found"
      return
    end

    sirens = test_establishments.group(:siren).count

    puts "📊 TEST ESTABLISHMENTS STATISTICS:"
    puts "   Total Companies: #{test_companies.count}"
    puts "   Total Establishments: #{test_establishments.count}"
    puts "   SIRENs used: #{sirens.count}"
    puts ""
    puts "📋 BY SIREN:"
    sirens.each do |siren, count|
      puts "   #{siren}: #{count} establishments"
    end

    min_siret = test_establishments.minimum(:siret)
    max_siret = test_establishments.maximum(:siret)
    puts ""
    puts "🔢 SIRET Range: #{min_siret} to #{max_siret}"
  end

  desc "Quick test with small dataset"
  task quick_test: :environment do
    unless Rails.env.development?
      puts "❌ This task can only be run in development environment"
      exit 1
    end

    puts "🚀 Creating quick test dataset (100 establishments)..."
    Rake::Task["test:create_establishments"].invoke(100)
  end

  desc "Performance test with large dataset"
  task performance_test: :environment do
    unless Rails.env.development?
      puts "❌ This task can only be run in development environment"
      exit 1
    end

    puts "🚀 Creating performance test dataset (100,000 establishments)..."
    puts "⚠️  This will take several minutes..."
    Rake::Task["test:create_establishments"].invoke(100_000)
  end
end
