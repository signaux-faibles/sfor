class Establishment < ApplicationRecord
  belongs_to :company
  belongs_to :activity_sector, optional: true
  belongs_to :level_one_activity_sector, class_name: "ActivitySector", optional: true
  belongs_to :department, optional: false
  belongs_to :parent_establishment, class_name: "Establishment", optional: true
  has_many :child_establishments, class_name: "Establishment", foreign_key: "parent_establishment_id"

  has_many :establishment_trackings
  has_many :contacts

  validates :siren, presence: true, length: { is: 9 }
  validates :siret, presence: true, length: { is: 14 }, uniqueness: { scope: :siren }

  def self.ransackable_attributes(_auth_object = nil)
    %w[activite_partielle activity_sector_id alert apconso_heure_consomme apconso_montant arrete_bilan
       chiffre_affaire code_activite code_departement code_territoire_industrie commune created_at date_creation_entreprise date_effectif date_entreprise date_last_procol date_ouverture_etablissement department_id detail_score dette_urssaf effectif effectif_entreprise etat_administratif etat_administratif_entreprise excedent_brut_d_exploitation exercice_diane first_alert first_list_entreprise first_list_etablissement first_red_list_entreprise first_red_list_etablissement has_delai hausse_urssaf id id_value last_alert last_list last_procol level_one_activity_sector_id libelle_departement libelle_n1 libelle_n5 libelle_territoire_industrie liste parent_company_id periode_urssaf presence_part_salariale prev_chiffre_affaire prev_excedent_brut_d_exploitation prev_resultat_expl raison_sociale raison_sociale_groupe resultat_expl roles secteur_covid siren siret statut_juridique_n1 statut_juridique_n2 statut_juridique_n3 territoire_industrie updated_at valeur_score variation_ca]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[activity_sector campaign_memberships campaigns department establishment_trackings
       level_one_activity_sector parent_company sub_establishments]
  end
end
