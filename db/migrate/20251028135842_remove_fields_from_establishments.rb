class RemoveFieldsFromEstablishments < ActiveRecord::Migration[7.2]
  def change
    # Drop old foreign keys
    remove_foreign_key :establishments, :companies if foreign_key_exists?(:establishments, :companies)
    remove_foreign_key :establishments, :departments if foreign_key_exists?(:establishments, :departments)
    remove_foreign_key :establishments, :activity_sectors if foreign_key_exists?(:establishments, :activity_sectors)
    remove_foreign_key :establishments, :activity_sectors, column: :level_one_activity_sector_id if foreign_key_exists?(:establishments, name: "fk_rails_establishments_level_one_activity_sector_id")
    remove_foreign_key :establishments, :establishments, column: :parent_establishment_id if foreign_key_exists?(:establishments, name: "fk_rails_establishments_parent_establishment_id")

    # Drop old indexes
    remove_index :establishments, :company_id if index_exists?(:establishments, :company_id)
    remove_index :establishments, :department_id if index_exists?(:establishments, :department_id)
    remove_index :establishments, :activity_sector_id if index_exists?(:establishments, :activity_sector_id)
    remove_index :establishments, :level_one_activity_sector_id if index_exists?(:establishments, :level_one_activity_sector_id)
    remove_index :establishments, :parent_establishment_id if index_exists?(:establishments, :parent_establishment_id)

    # Remove old columns (keep only the ones you want)
    columns_to_remove = [
      :roles,
      :raison_sociale,
      :valeur_score,
      :detail_score,
      :first_alert,
      :first_list_entreprise,
      :first_red_list_entreprise,
      :first_list_etablissement,
      :first_red_list_etablissement,
      :last_list,
      :last_alert,
      :liste,
      :chiffre_affaire,
      :prev_chiffre_affaire,
      :arrete_bilan,
      :exercice_diane,
      :variation_ca,
      :resultat_expl,
      :prev_resultat_expl,
      :excedent_brut_d_exploitation,
      :prev_excedent_brut_d_exploitation,
      :effectif,
      :effectif_entreprise,
      :date_entreprise,
      :date_effectif,
      :libelle_n5,
      :libelle_n1,
      :last_procol,
      :date_last_procol,
      :activite_partielle,
      :apconso_heure_consomme,
      :apconso_montant,
      :hausse_urssaf,
      :dette_urssaf,
      :periode_urssaf,
      :presence_part_salariale,
      :alert,
      :raison_sociale_groupe,
      :territoire_industrie,
      :code_territoire_industrie,
      :libelle_territoire_industrie,
      :statut_juridique_n3,
      :statut_juridique_n2,
      :statut_juridique_n1,
      :date_ouverture_etablissement,
      :date_creation_entreprise,
      :secteur_covid,
      :etat_administratif,
      :etat_administratif_entreprise,
      :has_delai,
      :company_id,
      :department_id,
      :activity_sector_id,
      :level_one_activity_sector_id,
      :parent_establishment_id
    ]

    columns_to_remove.each do |column|
      remove_column :establishments, column if column_exists?(:establishments, column)
    end

    # Rename is_siege to siege
    rename_column :establishments, :is_siege, :siege if column_exists?(:establishments, :is_siege)

    # Change code_activite from text to string(5)
    change_column :establishments, :code_activite, :string, limit: 5, null: true if column_exists?(:establishments, :code_activite)

    # Add new columns
    add_column :establishments, :complement_adresse, :text unless column_exists?(:establishments, :complement_adresse)
    add_column :establishments, :numero_voie, :string, limit: 10 unless column_exists?(:establishments, :numero_voie)
    add_column :establishments, :indrep, :string, limit: 10 unless column_exists?(:establishments, :indrep)
    add_column :establishments, :type_voie, :string, limit: 20 unless column_exists?(:establishments, :type_voie)
    add_column :establishments, :voie, :text unless column_exists?(:establishments, :voie)
    add_column :establishments, :commune_etranger, :text unless column_exists?(:establishments, :commune_etranger)
    add_column :establishments, :distribution_speciale, :text unless column_exists?(:establishments, :distribution_speciale)
    add_column :establishments, :code_commune, :string, limit: 5 unless column_exists?(:establishments, :code_commune)
    add_column :establishments, :code_cedex, :string, limit: 5 unless column_exists?(:establishments, :code_cedex)
    add_column :establishments, :cedex, :string, limit: 100 unless column_exists?(:establishments, :cedex)
    add_column :establishments, :code_pays_etranger, :string, limit: 10 unless column_exists?(:establishments, :code_pays_etranger)
    add_column :establishments, :pays_etranger, :string, limit: 100 unless column_exists?(:establishments, :pays_etranger)
    add_column :establishments, :code_postal, :string, limit: 10 unless column_exists?(:establishments, :code_postal)
    add_column :establishments, :departement, :string, limit: 10 unless column_exists?(:establishments, :departement)
    add_column :establishments, :ape, :string, limit: 100 unless column_exists?(:establishments, :ape)
    add_column :establishments, :nomenclature_activite, :string, limit: 10 unless column_exists?(:establishments, :nomenclature_activite)
    add_column :establishments, :date_creation, :date unless column_exists?(:establishments, :date_creation)
    add_column :establishments, :longitude, :float unless column_exists?(:establishments, :longitude)
    add_column :establishments, :latitude, :float unless column_exists?(:establishments, :latitude)

    # Add unique index on departments.code if it doesn't exist
    add_index :departments, :code, unique: true unless index_exists?(:departments, :code)
    
    # Add unique index on companies.siren if it doesn't exist
    add_index :companies, :siren, unique: true unless index_exists?(:companies, :siren)

    # Add foreign keys (using execute because they reference non-primary keys)
    unless foreign_key_exists?(:establishments, to_table: :companies, column: :siren)
      execute "ALTER TABLE establishments ADD CONSTRAINT fk_establishments_companies FOREIGN KEY (siren) REFERENCES companies(siren) ON DELETE RESTRICT ON UPDATE CASCADE"
    end

    unless foreign_key_exists?(:establishments, to_table: :departments, column: :departement)
      execute "ALTER TABLE establishments ADD CONSTRAINT fk_establishments_departments FOREIGN KEY (departement) REFERENCES departments(code) ON DELETE RESTRICT ON UPDATE CASCADE"
    end

    # Add index on departement
    add_index :establishments, :departement unless index_exists?(:establishments, :departement)
  end

  # Note: This migration cannot be fully reversed because:
  # 1. Data would be lost when re-adding removed columns
  # 2. Foreign keys reference non-primary keys which can't be easily recreated
  # 3. Column types and constraints would need manual reconstruction
  # 
  # If you need to rollback, restore from a database backup instead.
  
  def down
    # Remove new foreign keys
    execute "ALTER TABLE establishments DROP CONSTRAINT IF EXISTS fk_establishments_companies"
    execute "ALTER TABLE establishments DROP CONSTRAINT IF EXISTS fk_establishments_departments"
    
    # Remove new columns
    remove_column :establishments, :complement_adresse if column_exists?(:establishments, :complement_adresse)
    remove_column :establishments, :numero_voie if column_exists?(:establishments, :numero_voie)
    remove_column :establishments, :indrep if column_exists?(:establishments, :indrep)
    remove_column :establishments, :type_voie if column_exists?(:establishments, :type_voie)
    remove_column :establishments, :voie if column_exists?(:establishments, :voie)
    remove_column :establishments, :commune_etranger if column_exists?(:establishments, :commune_etranger)
    remove_column :establishments, :distribution_speciale if column_exists?(:establishments, :distribution_speciale)
    remove_column :establishments, :code_commune if column_exists?(:establishments, :code_commune)
    remove_column :establishments, :code_cedex if column_exists?(:establishments, :code_cedex)
    remove_column :establishments, :cedex if column_exists?(:establishments, :cedex)
    remove_column :establishments, :code_pays_etranger if column_exists?(:establishments, :code_pays_etranger)
    remove_column :establishments, :pays_etranger if column_exists?(:establishments, :pays_etranger)
    remove_column :establishments, :code_postal if column_exists?(:establishments, :code_postal)
    remove_column :establishments, :departement if column_exists?(:establishments, :departement)
    remove_column :establishments, :ape if column_exists?(:establishments, :ape)
    remove_column :establishments, :nomenclature_activite if column_exists?(:establishments, :nomenclature_activite)
    remove_column :establishments, :date_creation if column_exists?(:establishments, :date_creation)
    remove_column :establishments, :longitude if column_exists?(:establishments, :longitude)
    remove_column :establishments, :latitude if column_exists?(:establishments, :latitude)
    
    # Rename siege back to is_siege
    rename_column :establishments, :siege, :is_siege if column_exists?(:establishments, :siege)
    
    # Revert code_activite back to text
    change_column :establishments, :code_activite, :text if column_exists?(:establishments, :code_activite)
    
    # Note: We don't add back removed columns or restore foreign keys as this would be
    # complex and error-prone. If you need to revert, use a database backup.
  end
end
