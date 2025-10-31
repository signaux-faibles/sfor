class FinalizeSiretLinkAndDropOldEstablishmentId < ActiveRecord::Migration[7.2]
  def up
    change_column_null :establishment_trackings, :establishment_siret, false

    # Drop old FK + column
    remove_foreign_key :establishment_trackings, :establishments if foreign_key_exists?(:establishment_trackings, :establishments)
    remove_index  :establishment_trackings, :establishment_id if index_exists?(:establishment_trackings, :establishment_id)
    remove_column :establishment_trackings, :establishment_id
  end

  def down
    add_column :establishment_trackings, :establishment_id, :bigint
    add_index  :establishment_trackings, :establishment_id
    add_foreign_key :establishment_trackings, :establishments
    change_column_null :establishment_trackings, :establishment_siret, true
  end
end
