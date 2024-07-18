class CreateEstablishments < ActiveRecord::Migration[7.1]
  def change
    create_table :establishments do |t|
      t.text :roles
      t.string :siret, limit: 14
      t.string :siren, limit: 9
      t.text :raison_sociale
      t.text :commune
      t.float :valeur_score
      t.jsonb :detail_score
      t.boolean :first_alert
      t.text :first_list_entreprise
      t.text :first_red_list_entreprise
      t.text :first_list_etablissement
      t.text :first_red_list_etablissement
      t.text :last_list
      t.text :last_alert
      t.text :liste
      t.float :chiffre_affaire
      t.float :prev_chiffre_affaire
      t.date :arrete_bilan
      t.integer :exercice_diane
      t.float :variation_ca
      t.float :resultat_expl
      t.float :prev_resultat_expl
      t.float :excedent_brut_d_exploitation
      t.float :prev_excedent_brut_d_exploitation
      t.float :effectif
      t.float :effectif_entreprise
      t.date :date_entreprise
      t.date :date_effectif
      t.text :libelle_n5
      t.text :libelle_n1
      t.text :code_activite
      t.text :last_procol
      t.date :date_last_procol
      t.boolean :activite_partielle
      t.integer :apconso_heure_consomme
      t.integer :apconso_montant
      t.boolean :hausse_urssaf
      t.float :dette_urssaf
      t.date :periode_urssaf
      t.boolean :presence_part_salariale
      t.text :alert
      t.text :raison_sociale_groupe
      t.boolean :territoire_industrie
      t.text :code_territoire_industrie
      t.text :libelle_territoire_industrie
      t.text :statut_juridique_n3
      t.text :statut_juridique_n2
      t.text :statut_juridique_n1
      t.timestamp :date_ouverture_etablissement
      t.timestamp :date_creation_entreprise
      t.text :secteur_covid
      t.text :etat_administratif
      t.text :etat_administratif_entreprise
      t.boolean :has_delai
      t.integer :parent_company_id, index: true

      t.timestamps
    end
  end
end
