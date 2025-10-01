class DropLegacyOsfTables < ActiveRecord::Migration[7.2]
  def change
    drop_table :osf_apconsos, if_exists: true
    drop_table :osf_apdemandes, if_exists: true
  end
end
