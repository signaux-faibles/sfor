class AddDefaultsToRatingReasonsRatingsTimestamps < ActiveRecord::Migration[7.2]
  def up
    # Add default values for created_at and updated_at to support direct imports
    execute <<-SQL
      ALTER TABLE rating_reasons_ratings
      ALTER COLUMN created_at SET DEFAULT CURRENT_TIMESTAMP;
    SQL

    execute <<-SQL
      ALTER TABLE rating_reasons_ratings
      ALTER COLUMN updated_at SET DEFAULT CURRENT_TIMESTAMP;
    SQL
  end

  def down
    # Remove default values
    execute <<-SQL
      ALTER TABLE rating_reasons_ratings
      ALTER COLUMN created_at DROP DEFAULT;
    SQL

    execute <<-SQL
      ALTER TABLE rating_reasons_ratings
      ALTER COLUMN updated_at DROP DEFAULT;
    SQL
  end
end
