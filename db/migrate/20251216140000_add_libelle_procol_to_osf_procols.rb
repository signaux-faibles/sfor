class AddLibelleProcolToOsfProcols < ActiveRecord::Migration[7.2]
  def change
    add_column :osf_procols, :libelle_procol, :string
  end
end

