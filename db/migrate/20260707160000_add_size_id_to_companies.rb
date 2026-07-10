class AddSizeIdToCompanies < ActiveRecord::Migration[7.2]
  def change
    add_reference :companies, :size, null: true, foreign_key: true
  end
end
