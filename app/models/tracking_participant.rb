class TrackingParticipant < ApplicationRecord
  belongs_to :user
  belongs_to :establishment_tracking
end