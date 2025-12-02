class AddSirenToOsfProcols < ActiveRecord::Migration[7.2]
  def change
    add_column :osf_procols, :siren, :string, limit: 9
    add_index :osf_procols, :siren
  end
end
