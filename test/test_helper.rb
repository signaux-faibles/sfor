ENV["RAILS_ENV"] ||= "test"

require "simplecov"
SimpleCov.start

require_relative "../config/environment"
require "rails/test_help"
Rails.root.glob("test/support/**/*.rb").each { |file| require file }

# Ensure procol_at_date exists in test DB (schema.rb does not dump SQL functions).
# If the test DB was prepared with db:schema:load or db:drop failed so migrate ran as no-op,
# the function would be missing. Creating it here makes tests work in both cases.
if Rails.env.test?
  ActiveRecord::Base.connection_pool.with_connection do |conn|
    has_function = conn.execute("SELECT 1 FROM pg_proc WHERE proname = 'procol_at_date'").any?
    next if has_function

    # Only create if osf_procols exists (migrations may not have run)
    next unless conn.table_exists?("osf_procols")

    conn.execute(<<~SQL.squish)
      CREATE OR REPLACE FUNCTION procol_at_date(date_param date)
      RETURNS TABLE(siren VARCHAR(9), date_effet DATE, action_procol TEXT, stade_procol TEXT, libelle_procol TEXT) AS $$
        WITH last_action_procol AS (
          SELECT DISTINCT ON (siren, action_procol)
            siren, date_effet, action_procol, stade_procol, libelle_procol
          FROM osf_procols
          WHERE date_effet <= date_param
          ORDER BY siren, action_procol, date_effet DESC
        )
        SELECT siren, date_effet, action_procol, stade_procol, libelle_procol
        FROM last_action_procol
        WHERE stade_procol != 'fin_procedure';
      $$ LANGUAGE SQL;
    SQL
  end
end

module ActiveSupport
  class TestCase
    include Devise::Test::IntegrationHelpers
    include IntegrationTestHelpers

    # Single worker so the one test DB is prepared with db:migrate (and gets SQL functions like procol_at_date)
    parallelize(workers: 1)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
