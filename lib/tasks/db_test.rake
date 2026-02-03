# frozen_string_literal: true

namespace :db do # rubocop:disable Metrics/BlockLength
  namespace :test do # rubocop:disable Metrics/BlockLength
    desc "Terminate connections to the test DB(s) then drop them (use when db:drop fails with PG::ObjectInUse)"
    task drop_force: :environment do
      config = ActiveRecord::Base.configurations.configs_for(env_name: "test").first.configuration_hash
      base_name = config[:database]

      # Connect to postgres so we can drop the test DB (we can't drop a DB we're connected to)
      sys_config = config.merge(database: "postgres")
      ActiveRecord::Base.establish_connection(sys_config)
      conn = ActiveRecord::Base.connection

      # All test DBs: main + parallel clones (e.g. _test, _test-1, _test-2)
      test_dbs = conn.execute(<<~SQL.squish).map { |row| row["datname"] }
        SELECT datname FROM pg_database
        WHERE datname = #{conn.quote(base_name)}
           OR datname LIKE #{conn.quote("#{base_name}-%")}
        ORDER BY datname
      SQL

      test_dbs.each do |db_name|
        puts "Terminating connections to #{db_name}..."
        conn.execute(<<~SQL.squish)
          SELECT pg_terminate_backend(pg_stat_activity.pid)
          FROM pg_stat_activity
          WHERE pg_stat_activity.datname = #{conn.quote(db_name)}
            AND pid <> pg_backend_pid();
        SQL
        puts "Dropping database #{db_name}..."
        conn.execute("DROP DATABASE IF EXISTS #{conn.quote_column_name(db_name)}")
        puts "Dropped #{db_name}"
      end

      puts "Done. Run db:create db:migrate RAILS_ENV=test to recreate." if test_dbs.any?
    end
  end
end
