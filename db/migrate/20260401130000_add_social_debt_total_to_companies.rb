class AddSocialDebtTotalToCompanies < ActiveRecord::Migration[7.2]
  def change
    add_column :companies, :social_debt_total, :decimal, precision: 15, scale: 2
  end
end
