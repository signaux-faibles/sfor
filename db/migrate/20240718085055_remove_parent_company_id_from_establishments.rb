class RemoveParentCompanyIdFromEstablishments < ActiveRecord::Migration[7.1]
  def change
    remove_column :establishments, :parent_company_id, :integer
  end
end
