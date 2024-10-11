class LabelGroup < ApplicationRecord
  has_many :tracking_labels, dependent: :nullify

  validates :name, presence: true, uniqueness: true
end
