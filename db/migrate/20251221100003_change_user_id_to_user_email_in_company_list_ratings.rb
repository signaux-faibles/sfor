# frozen_string_literal: true

class ChangeUserIdToUserEmailInCompanyListRatings < ActiveRecord::Migration[7.2]
  def change
    # Remove foreign key first
    remove_foreign_key :company_list_ratings, :users

    # Remove old indexes
    remove_index :company_list_ratings, :user_id
    remove_index :company_list_ratings, name: "idx_company_list_ratings_unique"

    # Remove user_id column
    remove_column :company_list_ratings, :user_id, :bigint

    # Add user_email column
    add_column :company_list_ratings, :user_email, :string, null: false

    # Add user_segment column
    add_column :company_list_ratings, :user_segment, :string

    # Add new indexes
    add_index :company_list_ratings, :user_email
    add_index :company_list_ratings, :user_segment
    add_index :company_list_ratings, [:siren, :user_email, :list_name], unique: true, name: "idx_company_list_ratings_unique"
  end
end

