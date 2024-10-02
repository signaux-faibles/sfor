class AddContactColumnToEstablishmentTracking < ActiveRecord::Migration[7.1]
  def change
    add_column :establishment_trackings, :contact, :text
  end
end
