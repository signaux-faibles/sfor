class ChangeOsfProcolsToUseSirenOnly < ActiveRecord::Migration[7.2]
  def change
    if index_exists?(:osf_procols, :siret)
      remove_index :osf_procols, :siret
    end

    remove_column :osf_procols, :siret, :string, limit: 14
  end
end
