class Segment < ApplicationRecord
  has_many :users
  belongs_to :network, optional: false

  has_and_belongs_to_many :summaries
  has_and_belongs_to_many :comments

  validates :name, presence: true, uniqueness: true
end
