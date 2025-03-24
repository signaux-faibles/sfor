class MakeCompanyMandatoryForEstablishments < ActiveRecord::Migration[7.1]
  def change
    change_column_null :establishments, :company_id, false
  end
end
