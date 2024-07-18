class AddCompanyToEstablishments < ActiveRecord::Migration[7.1]
  def change
    add_reference :establishments, :company, null: true, foreign_key: true
    add_index :establishments, [:siren, :siret], unique: true
  end
end
