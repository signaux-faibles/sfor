class AddPerformanceIndexesForListsController < ActiveRecord::Migration[7.2]
  def change
    # 1. Index for effectif_min filter on osf_ent_effectifs
    # Query: WHERE siren IN (...) AND is_latest = true AND effectif >= ?
    # Partial index since we only query is_latest = true
    unless index_exists?(:osf_ent_effectifs, %i[siren is_latest effectif],
                         name: "index_osf_ent_effectifs_on_siren_is_latest_effectif")
      add_index :osf_ent_effectifs, %i[siren is_latest effectif],
                name: "index_osf_ent_effectifs_on_siren_is_latest_effectif",
                where: "is_latest = true"
    end

    # 2. Index for score_min filter on company_score_entries
    # Query: WHERE list_name = ? AND siren IN (...) AND score >= ?
    unless index_exists?(:company_score_entries, %i[list_name siren score],
                         name: "index_company_score_entries_on_list_name_siren_score")
      add_index :company_score_entries, %i[list_name siren score],
                name: "index_company_score_entries_on_list_name_siren_score"
    end

    # 3. Index for niveau_alerte filter on company_score_entries
    # Query: WHERE list_name = ? AND siren IN (...) AND alert = ?
    unless index_exists?(:company_score_entries, %i[list_name siren alert],
                         name: "index_company_score_entries_on_list_name_siren_alert")
      add_index :company_score_entries, %i[list_name siren alert],
                name: "index_company_score_entries_on_list_name_siren_alert"
    end

    # 4. Index for dette_sociale_min filter on osf_debits
    # Query: WHERE siret IN (...) AND is_last = true
    # Partial index since we only query is_last = true
    unless index_exists?(:osf_debits, %i[siret is_last],
                         name: "index_osf_debits_on_siret_is_last")
      add_index :osf_debits, %i[siret is_last],
                name: "index_osf_debits_on_siret_is_last",
                where: "is_last = true"
    end

    # 5. Index for sans_delai_urssaf filter on osf_delais
    # Query: WHERE siret IN (...) AND date_echeance > ?
    unless index_exists?(:osf_delais, %i[siret date_echeance],
                         name: "index_osf_delais_on_siret_date_echeance")
      add_index :osf_delais, %i[siret date_echeance],
                name: "index_osf_delais_on_siret_date_echeance"
    end

    # 6. Index for policy scope on establishments
    # Query: WHERE departement IN (...) AND siege = true
    unless index_exists?(:establishments, %i[departement siege],
                         name: "index_establishments_on_departement_siege")
      add_index :establishments, %i[departement siege],
                name: "index_establishments_on_departement_siege"
    end
  end
end

