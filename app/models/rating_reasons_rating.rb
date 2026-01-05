# frozen_string_literal: true

class RatingReasonsRating < ApplicationRecord
  self.table_name = "rating_reasons_ratings"

  belongs_to :rating, class_name: "CompanyListRating", foreign_key: :rating_id, optional: false
  belongs_to :rating_reason, foreign_key: :reason_id, optional: false

  validates :rating_id, uniqueness: { scope: :reason_id }
end
