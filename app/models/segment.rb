class Segment < ApplicationRecord
  has_many :users

  has_and_belongs_to_many :summaries
  has_and_belongs_to_many :comments
end
