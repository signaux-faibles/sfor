class AddLibellesAndIsActiveToCompanies < ActiveRecord::Migration[7.2]
  def change
    add_column :companies, :libelle_categorie_juridique, :string
    add_column :companies, :libelle_activite_principale, :string
    add_column :companies, :libelle_naf_section, :string
    add_column :companies, :is_active, :boolean
  end
end
