class Comment < ApplicationRecord
  belongs_to :establishment_tracking, optional: false
  belongs_to :network, optional: false
  belongs_to :user, optional: false

  after_create :update_establishment_tracking_modified_at

  validates :content, presence: true
  validates :network_id, presence: true

  private

  def update_establishment_tracking_modified_at
    establishment_tracking.update!(modified_at: Date.current)
  end
end
