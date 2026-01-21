class CreateListExportLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :list_export_logs do |t|
      t.datetime :exported_at, null: false
      t.string :user_email, null: false
      t.string :user_geo_zone, null: false
      t.string :user_segment, null: false
      t.string :list_name, null: false
      t.text :active_filters
      t.integer :results_count

      t.timestamps
    end

    add_index :list_export_logs, :exported_at
    add_index :list_export_logs, :user_email
    add_index :list_export_logs, :list_name
    add_index :list_export_logs, %i[user_email list_name exported_at], name: "index_list_export_logs_unique_daily"
  end
end
