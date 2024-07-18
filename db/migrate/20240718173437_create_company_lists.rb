class CreateCompanyLists < ActiveRecord::Migration[7.1]
  def change
    create_table :company_lists do |t|
      t.references :company, null: false, foreign_key: true
      t.references :list, null: false, foreign_key: true

      t.timestamps
    end
  end
end
