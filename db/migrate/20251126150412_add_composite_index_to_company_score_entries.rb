class AddCompositeIndexToCompanyScoreEntries < ActiveRecord::Migration[7.2]
  def change
    def up
      # Add composite index on [list_name, siren] to optimize DISTINCT queries
      # This index will help with queries like:
      # SELECT DISTINCT siren FROM company_score_entries WHERE list_name = ?
      add_index :company_score_entries, [:list_name, :siren], 
                name: 'index_company_score_entries_on_list_name_and_siren',
                unless_exists: true
    end
  
    def down
      remove_index :company_score_entries, 
                   name: 'index_company_score_entries_on_list_name_and_siren',
                   if_exists: true
    end
  end
end
