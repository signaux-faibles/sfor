# frozen_string_literal: true

class CreateRatingReasons < ActiveRecord::Migration[7.2]
  def change
    create_table :rating_reasons do |t|
      t.string :code, limit: 10, null: false
      t.text :libelle, null: false

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :rating_reasons, :code, unique: true
  end
end

