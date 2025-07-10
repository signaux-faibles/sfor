class TrackingEvent < ApplicationRecord
  belongs_to :establishment_tracking
  belongs_to :triggered_by_user, class_name: "User"
  has_many :establishment_tracking_snapshots, dependent: :destroy

  validates :event_type, presence: true
  validates :event_type, inclusion: {
    in: %w[creation update state_change referents_change participants_change]
  }

  scope :of_type, ->(type) { where(event_type: type) }
  scope :recent, -> { order(created_at: :desc) }

  def self.create_event!(establishment_tracking:, event_type:,
                         triggered_by_user:, description: nil, changes_summary: {})
    event = create!(
      establishment_tracking: establishment_tracking,
      event_type: event_type,
      triggered_by_user: triggered_by_user,
      description: description || "#{event_type.humanize} for tracking ##{establishment_tracking.id}",
      changes_summary: changes_summary
    )

    # Create snapshot after event is created
    establishment_tracking.snapshot_service.create_snapshot!(event)

    event
  end
end
