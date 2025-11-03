class RemoveForeignKeysFromEstablishmentsAndRelatedTables < ActiveRecord::Migration[7.2]
  def up
    # Remove all foreign keys to allow flexible deletion/recreation for performance
    # Referential integrity will be handled at the application level
    execute "ALTER TABLE establishments DROP CONSTRAINT IF EXISTS fk_establishments_companies"
    execute "ALTER TABLE establishments DROP CONSTRAINT IF EXISTS fk_establishments_departments"
    execute "ALTER TABLE establishment_trackings DROP CONSTRAINT IF EXISTS fk_etabl_trackings_establishments_siret"
    execute "ALTER TABLE contacts DROP CONSTRAINT IF EXISTS fk_contacts_establishments_siret"
  end

  def down
    # Re-add foreign key from establishments to companies
    execute <<-SQL
      ALTER TABLE establishments
      ADD CONSTRAINT fk_establishments_companies
      FOREIGN KEY (siren) REFERENCES companies(siren) ON DELETE RESTRICT ON UPDATE CASCADE
    SQL
    
    # Re-add foreign key from establishments to departments
    execute <<-SQL
      ALTER TABLE establishments
      ADD CONSTRAINT fk_establishments_departments
      FOREIGN KEY (departement) REFERENCES departments(code) ON DELETE RESTRICT ON UPDATE CASCADE
    SQL
    
    # Re-add foreign key from establishment_trackings to establishments
    execute <<-SQL
      ALTER TABLE establishment_trackings
      ADD CONSTRAINT fk_etabl_trackings_establishments_siret
      FOREIGN KEY (establishment_siret) REFERENCES establishments(siret)
      DEFERRABLE INITIALLY DEFERRED
    SQL
    
    # Re-add foreign key from contacts to establishments
    execute <<-SQL
      ALTER TABLE contacts
      ADD CONSTRAINT fk_contacts_establishments_siret
      FOREIGN KEY (establishment_siret) REFERENCES establishments(siret)
      DEFERRABLE INITIALLY DEFERRED
    SQL
  end
end
