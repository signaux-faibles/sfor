# frozen_string_literal: true

class CreateCompanyListRatings < ActiveRecord::Migration[7.2]
  def change
    create_table :company_list_ratings do |t|
      t.string :siren, limit: 9, null: false
      t.string :list_name, null: false
      t.bigint :user_id, null: false
      t.boolean :useful, null: false
      t.text :comment

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :company_list_ratings, :siren
    add_index :company_list_ratings, :list_name
    add_index :company_list_ratings, :user_id
    add_index :company_list_ratings, :useful
    add_index :company_list_ratings, [:siren, :user_id, :list_name], unique: true, name: "idx_company_list_ratings_unique"

    add_foreign_key :company_list_ratings, :users
    # Note: siren is not the primary key of companies, so we can't use a foreign key constraint
    # We rely on application-level validation instead
    # Note: list_name references lists.label, but label is not the primary key, so we can't use a foreign key constraint
    # We rely on application-level validation instead
  end
end

