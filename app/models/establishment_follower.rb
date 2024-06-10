class EstablishmentFollower < ApplicationRecord
  belongs_to :user
  belongs_to :establishment

  validates :status, inclusion: { in: ['in progress', 'done'] }
end
