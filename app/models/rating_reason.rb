# frozen_string_literal: true

class RatingReason < ApplicationRecord
  has_many :rating_reasons_ratings, dependent: :destroy
  has_many :ratings, through: :rating_reasons_ratings

  validates :code, presence: true, uniqueness: true, length: { maximum: 10 }
  validates :libelle, presence: true
end
