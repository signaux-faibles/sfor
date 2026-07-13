# frozen_string_literal: true

class AddMacroExplScoreColumnsToCompanyLists < ActiveRecord::Migration[8.1]
  def change
    add_column :company_lists, :score_age, :integer
    add_column :company_lists, :score_cluster_economique, :integer

    remove_index :company_lists, name: "index_company_lists_on_list_id_score_covering"

    add_index :company_lists, [:list_id, :score],
              name: "index_company_lists_on_list_id_score_covering",
              include: %i[
                siren alert score_age score_cluster_economique
                score_effectif score_financier score_dettes score_ap
              ]
  end
end
