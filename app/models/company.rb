class Company < ApplicationRecord
  has_many :establishments

  validates :siren, presence: true, uniqueness: true
  validates :siret, presence: true, uniqueness: true
end
