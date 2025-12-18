class AddIndexOnCompanyScoreEntriesListNameAndSiren < ActiveRecord::Migration[7.2]
  def change
    # Composite index to speed up DISTINCT siren queries scoped by list_name, e.g.:
    # SELECT COUNT(DISTINCT siren) FROM company_score_entries WHERE list_name = ?
    unless index_exists?(:company_score_entries, %i[list_name siren],
                         name: "index_company_score_entries_on_list_name_and_siren")
      add_index :company_score_entries, %i[list_name siren],
                name: "index_company_score_entries_on_list_name_and_siren"
    end
  end
end
