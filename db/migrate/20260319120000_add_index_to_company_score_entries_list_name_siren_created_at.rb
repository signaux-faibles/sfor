class AddIndexToCompanyScoreEntriesListNameSirenCreatedAt < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_index :company_score_entries,
              [:list_name, :siren, :created_at],
              order: { created_at: :desc },
              algorithm: :concurrently,
              name: "index_company_score_entries_on_list_name_siren_created_at"
  end
end
