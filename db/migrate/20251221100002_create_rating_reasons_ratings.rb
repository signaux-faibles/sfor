# frozen_string_literal: true

class CreateRatingReasonsRatings < ActiveRecord::Migration[7.2]
  def change
    create_table :rating_reasons_ratings do |t|
      t.bigint :rating_id, null: false
      t.bigint :reason_id, null: false

      t.timestamps
    end

    add_index :rating_reasons_ratings, :rating_id
    add_index :rating_reasons_ratings, :reason_id
    add_index :rating_reasons_ratings, [:rating_id, :reason_id], unique: true, name: "idx_rating_reasons_ratings_unique"

    add_foreign_key :rating_reasons_ratings, :company_list_ratings, column: :rating_id, on_delete: :cascade
    add_foreign_key :rating_reasons_ratings, :rating_reasons, column: :reason_id, on_delete: :cascade
  end
end

