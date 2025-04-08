class Comment < ApplicationRecord
  has_paper_trail

  belongs_to :establishment_tracking, optional: false
  belongs_to :network, optional: false
  belongs_to :user, optional: false

  after_create :update_establishment_tracking_modified_at
  after_create :create_establishment_tracking_version
  after_update :create_establishment_tracking_version
  after_destroy :create_establishment_tracking_version

  validates :content, presence: true
  validates :network_id, presence: true

  private

  def update_establishment_tracking_modified_at
    return if establishment_tracking.instance_variable_get(:@skip_modified_at_update)

    establishment_tracking.update!(modified_at: Date.current)
  end

  def create_establishment_tracking_version
    return if establishment_tracking.instance_variable_get(:@skip_modified_at_update)

    event_type = if destroyed?
                   "deleted"
                 elsif previous_changes.key?("id")
                   "created"
                 else
                   "modified"
                 end

    establishment_tracking.paper_trail_event = "comment_#{event_type}"
    establishment_tracking.paper_trail.save_with_version
  end
end
