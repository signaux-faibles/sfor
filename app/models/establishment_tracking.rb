class EstablishmentTracking < ApplicationRecord
  belongs_to :creator, class_name: 'User'
  belongs_to :establishment

  has_many :tracking_referents, dependent: :destroy
  has_many :referents, through: :tracking_referents, source: :user

  has_many :tracking_participants, dependent: :destroy
  has_many :participants, through: :tracking_participants, source: :user

  has_many :establishment_tracking_labels, dependent: :destroy
  has_many :tracking_labels, through: :establishment_tracking_labels

  validates :referents, presence: true
end