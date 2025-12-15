class AddDefaultsToSjcfCompaniesTimestamps < ActiveRecord::Migration[7.2]
  def up
    # Align timestamps defaults with other import-friendly tables
    execute <<-SQL
      ALTER TABLE sjcf_companies
      ALTER COLUMN created_at SET DEFAULT CURRENT_TIMESTAMP;
    SQL

    execute <<-SQL
      ALTER TABLE sjcf_companies
      ALTER COLUMN updated_at SET DEFAULT CURRENT_TIMESTAMP;
    SQL
  end

  def down
    execute <<-SQL
      ALTER TABLE sjcf_companies
      ALTER COLUMN created_at DROP DEFAULT;
    SQL

    execute <<-SQL
      ALTER TABLE sjcf_companies
      ALTER COLUMN updated_at DROP DEFAULT;
    SQL
  end
end
