class CreateAppSettings < ActiveRecord::Migration[7.1]
  def change
    create_table :app_settings do |t|
      t.boolean :maintenance_mode, null: false, default: false

      t.timestamps
    end
  end
end

