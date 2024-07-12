class EstablishmentTracking < ApplicationRecord
  belongs_to :creator, class_name: 'User'
  belongs_to :establishment
  has_many :tracking_participants, dependent: :destroy
  has_many :participants, through: :tracking_participants, source: :user

  after_create :add_creator_as_participant

  private

  def add_creator_as_participant
    self.participants << creator unless self.participants.include?(creator)
  end
end