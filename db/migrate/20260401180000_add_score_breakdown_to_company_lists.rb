class AddScoreBreakdownToCompanyLists < ActiveRecord::Migration[7.2]
  def change
    add_column :company_lists, :score_effectif,  :integer
    add_column :company_lists, :score_financier, :integer
    add_column :company_lists, :score_dettes,    :integer
    add_column :company_lists, :score_ap,        :integer
  end
end
