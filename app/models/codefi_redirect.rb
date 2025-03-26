class CodefiRedirect < ApplicationRecord
  has_and_belongs_to_many :establishment_trackings

  validates :name, presence: true, uniqueness: true

  scope :ordered, -> { order(position: :asc) }
  default_scope { order(position: :asc) }
end
