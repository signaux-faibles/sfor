class AddPrimaryKeyToCodefiRedirectsEstablishmentTrackings < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      ALTER TABLE codefi_redirects_establishment_trackings
      ADD COLUMN id bigserial;
    SQL

    execute <<~SQL
      ALTER TABLE codefi_redirects_establishment_trackings
      ADD PRIMARY KEY (id);
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE codefi_redirects_establishment_trackings
      DROP CONSTRAINT codefi_redirects_establishment_trackings_pkey;
    SQL

    execute <<~SQL
      ALTER TABLE codefi_redirects_establishment_trackings
      DROP COLUMN id;
    SQL
  end
end
