class AddEntreprisesRecentesFilterDateToAppSettings < ActiveRecord::Migration[7.1]
  def change
    add_column :app_settings, :entreprises_recentes_filter_date, :date
  end
end
