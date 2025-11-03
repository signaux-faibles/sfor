class FinalizeSiretLinkForContactsAndDropOldEstablishmentId < ActiveRecord::Migration[7.2]
  def up
    change_column_null :contacts, :establishment_siret, false

    # Drop old FK + column
    remove_foreign_key :contacts, :establishments if foreign_key_exists?(:contacts, :establishments)
    remove_index  :contacts, :establishment_id if index_exists?(:contacts, :establishment_id)
    remove_column :contacts, :establishment_id
  end

  def down
    add_column :contacts, :establishment_id, :bigint
    add_index  :contacts, :establishment_id
    add_foreign_key :contacts, :establishments
    change_column_null :contacts, :establishment_siret, true
  end
end
