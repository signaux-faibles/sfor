class EstablishmentTrackingAction < ApplicationRecord
  belongs_to :establishment_tracking
  belongs_to :user_action
end
