class Action < ApplicationRecord
  has_many :establishment_tracking_actions, dependent: :destroy
  has_many :establishment_trackings, through: :establishment_tracking_actions

  validates :name, presence: true, uniqueness: true
end
