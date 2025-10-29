class ReshapeCompaniesForNewSchema < ActiveRecord::Migration[7.2]
  def change
    # 1) Drop existing foreign keys/indexes referencing removed columns
    remove_foreign_key :companies, :departments if foreign_key_exists?(:companies, :departments)
    remove_foreign_key :companies, :activity_sectors if foreign_key_exists?(:companies, :activity_sectors)

    remove_index :companies, :department_id if index_exists?(:companies, :department_id)
    remove_index :companies, :activity_sector_id if index_exists?(:companies, :activity_sector_id)
    remove_index :companies, :siret if index_exists?(:companies, :siret)

    # 2) Ensure siren is varchar(9), keep it as the business key
    change_column :companies, :siren, :string, limit: 9, null: true if column_exists?(:companies, :siren)
    add_index :companies, :siren, unique: true unless index_exists?(:companies, :siren)

    # 3) raison_sociale to text
    change_column :companies, :raison_sociale, :text if column_exists?(:companies, :raison_sociale)

    # 4) Add new columns
    add_column :companies, :statut_juridique, :string, limit: 10 unless column_exists?(:companies, :statut_juridique)
    add_column :companies, :creation, :date unless column_exists?(:companies, :creation)

    # 5) Remove columns no longer needed
    remove_column :companies, :siret if column_exists?(:companies, :siret)
    remove_column :companies, :effectif if column_exists?(:companies, :effectif)
    remove_column :companies, :department_id if column_exists?(:companies, :department_id)
    remove_column :companies, :activity_sector_id if column_exists?(:companies, :activity_sector_id)
  end
end
