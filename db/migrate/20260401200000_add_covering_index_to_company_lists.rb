class AddCoveringIndexToCompanyLists < ActiveRecord::Migration[7.2]
  def change
    # Replace the bare (list_id, score) index with a covering version so the
    # list_scores CTE in the Excel generator and the controller pagination can
    # both run as index-only scans — no heap fetch needed for any of these columns.
    remove_index :company_lists, name: "index_company_lists_on_list_id_and_score"

    add_index :company_lists, [:list_id, :score],
              name: "index_company_lists_on_list_id_score_covering",
              include: [:siren, :alert, :score_effectif, :score_financier, :score_dettes, :score_ap]
  end
end
