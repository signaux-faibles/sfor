# frozen_string_literal: true

class CompanyListRating < ApplicationRecord
  belongs_to :company, foreign_key: :siren, primary_key: :siren, optional: false
  belongs_to :list, foreign_key: :list_name, primary_key: :label, optional: false
  has_many :rating_reasons_ratings, foreign_key: :rating_id, dependent: :destroy
  has_many :rating_reasons, through: :rating_reasons_ratings

  validates :siren, presence: true, length: { is: 9 }
  validates :list_name, presence: true
  validates :user_email, presence: true
  validates :useful, inclusion: { in: [true, false] }
  validates :siren, uniqueness: { scope: %i[user_email list_name] }

  scope :useful, -> { where(useful: true) }
  scope :not_useful, -> { where(useful: false) }
end
