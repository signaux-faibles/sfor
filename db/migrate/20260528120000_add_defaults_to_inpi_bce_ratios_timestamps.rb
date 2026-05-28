class AddDefaultsToInpiBceRatiosTimestamps < ActiveRecord::Migration[7.2]
  def up
    execute <<-SQL
      ALTER TABLE inpi_bce_ratios
      ALTER COLUMN created_at SET DEFAULT CURRENT_TIMESTAMP;
    SQL

    execute <<-SQL
      ALTER TABLE inpi_bce_ratios
      ALTER COLUMN updated_at SET DEFAULT CURRENT_TIMESTAMP;
    SQL
  end

  def down
    execute <<-SQL
      ALTER TABLE inpi_bce_ratios
      ALTER COLUMN created_at DROP DEFAULT;
    SQL

    execute <<-SQL
      ALTER TABLE inpi_bce_ratios
      ALTER COLUMN updated_at DROP DEFAULT;
    SQL
  end
end
