class AddEstablishmentSiretToEstablishmentTrackings < ActiveRecord::Migration[7.2]
  def up
    add_column :establishment_trackings, :establishment_siret, :string
    add_index  :establishment_trackings, :establishment_siret

    # Backfill from existing relation
    execute <<-SQL
      UPDATE establishment_trackings et
      SET establishment_siret = e.siret
      FROM establishments e
      WHERE e.id = et.establishment_id
    SQL

    # Create deferrable FK on siret (non-PK)
    execute <<-SQL
      ALTER TABLE establishment_trackings
      ADD CONSTRAINT fk_etabl_trackings_establishments_siret
      FOREIGN KEY (establishment_siret)
      REFERENCES establishments(siret)
      DEFERRABLE INITIALLY DEFERRED
    SQL
  end

  def down
    execute "ALTER TABLE establishment_trackings DROP CONSTRAINT IF EXISTS fk_etabl_trackings_establishments_siret"
    remove_index  :establishment_trackings, :establishment_siret
    remove_column :establishment_trackings, :establishment_siret
  end
end
