class DropRedundantIndexesOnCompanyScoreEntries < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def up
    # GIN indexes on JSONB columns — only benefit JSONB containment operators (@>, ?, ?|, ?&).
    # The app extracts values with ->>'key' which never uses GIN. Each is ~600MB+.
    remove_index :company_score_entries, name: "index_company_score_entries_on_macro_expl",
                 algorithm: :concurrently, if_exists: true
    remove_index :company_score_entries, name: "index_company_score_entries_on_micro_expl",
                 algorithm: :concurrently, if_exists: true

    # (list_name) — fully covered by every (list_name, siren, X) index as the leading column.
    remove_index :company_score_entries, name: "index_company_score_entries_on_list_name",
                 algorithm: :concurrently, if_exists: true

    # (siren) — fully covered by the (siren, list_name, periode) unique index.
    remove_index :company_score_entries, name: "index_company_score_entries_on_siren",
                 algorithm: :concurrently, if_exists: true

    # (list_name, siren) — redundant: any of the three (list_name, siren, X) indexes
    # can serve queries on (list_name, siren) using the first two columns as a prefix.
    remove_index :company_score_entries, name: "index_company_score_entries_on_list_name_and_siren",
                 algorithm: :concurrently, if_exists: true
  end

  def down
    add_index :company_score_entries, [:list_name, :siren],
              name: "index_company_score_entries_on_list_name_and_siren",
              algorithm: :concurrently
    add_index :company_score_entries, :siren,
              name: "index_company_score_entries_on_siren",
              algorithm: :concurrently
    add_index :company_score_entries, :list_name,
              name: "index_company_score_entries_on_list_name",
              algorithm: :concurrently
    add_index :company_score_entries, :macro_expl,
              name: "index_company_score_entries_on_macro_expl",
              using: :gin, algorithm: :concurrently
    add_index :company_score_entries, :micro_expl,
              name: "index_company_score_entries_on_micro_expl",
              using: :gin, algorithm: :concurrently
  end
end
