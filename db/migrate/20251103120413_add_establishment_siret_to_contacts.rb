class AddEstablishmentSiretToContacts < ActiveRecord::Migration[7.2]
  def up
    add_column :contacts, :establishment_siret, :string
    add_index  :contacts, :establishment_siret

    # Backfill from existing relation
    execute <<-SQL
      UPDATE contacts c
      SET establishment_siret = e.siret
      FROM establishments e
      WHERE e.id = c.establishment_id
    SQL

    # Create deferrable FK on siret (non-PK)
    execute <<-SQL
      ALTER TABLE contacts
      ADD CONSTRAINT fk_contacts_establishments_siret
      FOREIGN KEY (establishment_siret)
      REFERENCES establishments(siret)
      DEFERRABLE INITIALLY DEFERRED
    SQL
  end

  def down
    execute "ALTER TABLE contacts DROP CONSTRAINT IF EXISTS fk_contacts_establishments_siret"
    remove_index  :contacts, :establishment_siret
    remove_column :contacts, :establishment_siret
  end
end
