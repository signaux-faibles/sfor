ENV["RAILS_ENV"] ||= "test"

require "simplecov"
SimpleCov.start

require_relative "../config/environment"
require "rails/test_help"
Rails.root.glob("test/support/**/*.rb").each { |file| require file }

module ActiveSupport
  class TestCase
    include Devise::Test::IntegrationHelpers
    include IntegrationTestHelpers

    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
