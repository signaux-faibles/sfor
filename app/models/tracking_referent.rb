class TrackingReferent < ApplicationRecord
  belongs_to :establishment_tracking
  belongs_to :user
end
