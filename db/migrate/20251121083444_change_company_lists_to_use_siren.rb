class ChangeCompanyListsToUseSiren < ActiveRecord::Migration[7.2]
  def up
    # Step 1: Update company_lists table
    # Remove foreign key constraint
    remove_foreign_key :company_lists, :companies if foreign_key_exists?(:company_lists, :companies)
    
    # Remove old index
    remove_index :company_lists, :company_id if index_exists?(:company_lists, :company_id)
    
    # Add siren column
    add_column :company_lists, :siren, :string, limit: 9 unless column_exists?(:company_lists, :siren)
    
    # Migrate data: copy siren from companies table
    execute <<-SQL
      UPDATE company_lists
      SET siren = companies.siren
      FROM companies
      WHERE company_lists.company_id = companies.id
    SQL
    
    # Make siren NOT NULL after data migration
    change_column_null :company_lists, :siren, false
    
    # Remove company_id column
    remove_column :company_lists, :company_id if column_exists?(:company_lists, :company_id)
    
    # Add new indexes
    add_index :company_lists, :siren unless index_exists?(:company_lists, :siren)
    add_index :company_lists, [:siren, :list_id], unique: true unless index_exists?(:company_lists, [:siren, :list_id])
    
    # Step 2: Update company_score_entries table
    # Remove foreign key constraint
    remove_foreign_key :company_score_entries, :companies if foreign_key_exists?(:company_score_entries, :companies)
    
    # Remove old indexes
    remove_index :company_score_entries, :company_id if index_exists?(:company_score_entries, :company_id)
    remove_index :company_score_entries, [:company_id, :list_id, :periode] if index_exists?(:company_score_entries, [:company_id, :list_id, :periode])
    
    # Remove company_id column (siren already exists)
    remove_column :company_score_entries, :company_id if column_exists?(:company_score_entries, :company_id)
    
    # Add new indexes
    add_index :company_score_entries, [:siren, :list_id, :periode], unique: true unless index_exists?(:company_score_entries, [:siren, :list_id, :periode])
  end

  def down
    # Revert company_score_entries
    add_column :company_score_entries, :company_id, :bigint unless column_exists?(:company_score_entries, :company_id)
    
    # Migrate data back
    execute <<-SQL
      UPDATE company_score_entries
      SET company_id = companies.id
      FROM companies
      WHERE company_score_entries.siren = companies.siren
    SQL
    
    change_column_null :company_score_entries, :company_id, false
    
    add_foreign_key :company_score_entries, :companies
    add_index :company_score_entries, :company_id
    add_index :company_score_entries, [:company_id, :list_id, :periode]
    remove_index :company_score_entries, [:siren, :list_id, :periode] if index_exists?(:company_score_entries, [:siren, :list_id, :periode])
    
    # Revert company_lists
    add_column :company_lists, :company_id, :bigint unless column_exists?(:company_lists, :company_id)
    
    # Migrate data back
    execute <<-SQL
      UPDATE company_lists
      SET company_id = companies.id
      FROM companies
      WHERE company_lists.siren = companies.siren
    SQL
    
    change_column_null :company_lists, :company_id, false
    
    remove_index :company_lists, [:siren, :list_id] if index_exists?(:company_lists, [:siren, :list_id])
    remove_index :company_lists, :siren if index_exists?(:company_lists, :siren)
    remove_column :company_lists, :siren if column_exists?(:company_lists, :siren)
    
    add_foreign_key :company_lists, :companies
    add_index :company_lists, :company_id
  end
end
