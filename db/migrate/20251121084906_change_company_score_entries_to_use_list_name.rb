class ChangeCompanyScoreEntriesToUseListName < ActiveRecord::Migration[7.2]
  def up
    # Step 1: Add list_name column
    add_column :company_score_entries, :list_name, :string unless column_exists?(:company_score_entries, :list_name)
    
    # Step 2: Migrate data: copy label from lists table
    execute <<-SQL
      UPDATE company_score_entries
      SET list_name = lists.label
      FROM lists
      WHERE company_score_entries.list_id = lists.id
    SQL
    
    # Step 3: Make list_name NOT NULL after data migration
    change_column_null :company_score_entries, :list_name, false
    
    # Step 4: Remove foreign key constraint
    remove_foreign_key :company_score_entries, :lists if foreign_key_exists?(:company_score_entries, :lists)
    
    # Step 5: Remove old indexes
    remove_index :company_score_entries, :list_id if index_exists?(:company_score_entries, :list_id)
    remove_index :company_score_entries, [:company_id, :list_id, :periode] if index_exists?(:company_score_entries, [:company_id, :list_id, :periode])
    remove_index :company_score_entries, [:siren, :list_id, :periode] if index_exists?(:company_score_entries, [:siren, :list_id, :periode])
    
    # Step 6: Remove list_id column
    remove_column :company_score_entries, :list_id if column_exists?(:company_score_entries, :list_id)
    
    # Step 7: Add new indexes
    add_index :company_score_entries, :list_name unless index_exists?(:company_score_entries, :list_name)
    add_index :company_score_entries, [:siren, :list_name, :periode], unique: true unless index_exists?(:company_score_entries, [:siren, :list_name, :periode])
  end

  def down
    # Revert company_score_entries
    add_column :company_score_entries, :list_id, :bigint unless column_exists?(:company_score_entries, :list_id)
    
    # Migrate data back
    execute <<-SQL
      UPDATE company_score_entries
      SET list_id = lists.id
      FROM lists
      WHERE company_score_entries.list_name = lists.label
    SQL
    
    change_column_null :company_score_entries, :list_id, false
    
    add_foreign_key :company_score_entries, :lists
    add_index :company_score_entries, :list_id
    add_index :company_score_entries, [:siren, :list_id, :periode]
    
    remove_index :company_score_entries, [:siren, :list_name, :periode] if index_exists?(:company_score_entries, [:siren, :list_name, :periode])
    remove_index :company_score_entries, :list_name if index_exists?(:company_score_entries, :list_name)
    remove_column :company_score_entries, :list_name if column_exists?(:company_score_entries, :list_name)
  end
end
