class AddAddressToEstablishmentsAndRemoveAddressFields < ActiveRecord::Migration[7.2]
  def up
    # Add address column
    add_column :establishments, :address, :text unless column_exists?(:establishments, :address)
    
    # Remove address-related fields
    remove_column :establishments, :complement_adresse, :text if column_exists?(:establishments, :complement_adresse)
    remove_column :establishments, :numero_voie, :string, limit: 10 if column_exists?(:establishments, :numero_voie)
    remove_column :establishments, :indrep, :string, limit: 10 if column_exists?(:establishments, :indrep)
    remove_column :establishments, :type_voie, :string, limit: 20 if column_exists?(:establishments, :type_voie)
    remove_column :establishments, :voie, :text if column_exists?(:establishments, :voie)
    remove_column :establishments, :commune_etranger, :text if column_exists?(:establishments, :commune_etranger)
    remove_column :establishments, :distribution_speciale, :text if column_exists?(:establishments, :distribution_speciale)
    remove_column :establishments, :code_cedex, :string, limit: 5 if column_exists?(:establishments, :code_cedex)
    remove_column :establishments, :cedex, :string, limit: 100 if column_exists?(:establishments, :cedex)
    remove_column :establishments, :code_pays_etranger, :string, limit: 10 if column_exists?(:establishments, :code_pays_etranger)
    remove_column :establishments, :pays_etranger, :string, limit: 100 if column_exists?(:establishments, :pays_etranger)
    remove_column :establishments, :code_postal, :string, limit: 10 if column_exists?(:establishments, :code_postal)
    remove_column :establishments, :nomenclature_activite, :string, limit: 10 if column_exists?(:establishments, :nomenclature_activite)
    remove_column :establishments, :commune, :text if column_exists?(:establishments, :commune)
  end

  def down
    # Remove address column
    remove_column :establishments, :address if column_exists?(:establishments, :address)
    
    # Restore address-related fields
    add_column :establishments, :complement_adresse, :text unless column_exists?(:establishments, :complement_adresse)
    add_column :establishments, :numero_voie, :string, limit: 10 unless column_exists?(:establishments, :numero_voie)
    add_column :establishments, :indrep, :string, limit: 10 unless column_exists?(:establishments, :indrep)
    add_column :establishments, :type_voie, :string, limit: 20 unless column_exists?(:establishments, :type_voie)
    add_column :establishments, :voie, :text unless column_exists?(:establishments, :voie)
    add_column :establishments, :commune_etranger, :text unless column_exists?(:establishments, :commune_etranger)
    add_column :establishments, :distribution_speciale, :text unless column_exists?(:establishments, :distribution_speciale)
    add_column :establishments, :code_cedex, :string, limit: 5 unless column_exists?(:establishments, :code_cedex)
    add_column :establishments, :cedex, :string, limit: 100 unless column_exists?(:establishments, :cedex)
    add_column :establishments, :code_pays_etranger, :string, limit: 10 unless column_exists?(:establishments, :code_pays_etranger)
    add_column :establishments, :pays_etranger, :string, limit: 100 unless column_exists?(:establishments, :pays_etranger)
    add_column :establishments, :code_postal, :string, limit: 10 unless column_exists?(:establishments, :code_postal)
    add_column :establishments, :nomenclature_activite, :string, limit: 10 unless column_exists?(:establishments, :nomenclature_activite)
    add_column :establishments, :commune, :text unless column_exists?(:establishments, :commune)
  end
end
