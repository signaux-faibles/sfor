class Notification < ApplicationRecord
  belongs_to :created_by, class_name: "User", optional: true

  has_and_belongs_to_many :segments
  has_many :notification_reads, dependent: :destroy
  has_many :readers, through: :notification_reads, source: :user

  validates :title, :body, presence: true
  validates :show_as_flash, inclusion: { in: %w[success error information warning], allow_nil: true }
  validate :segments_presence

  scope :for_user, lambda { |user|
    where(
      id: joins(:segments)
        .where(segments: { id: user.segment_id })
        .select(:id)
    )
  }

  scope :unread_for_user, lambda { |user|
    where.not(
      id: user.notification_reads.where.not(read_at: nil).select(:notification_id)
    )
  }

  private

  def segments_presence
    errors.add(:segments, "doit contenir au moins un segment") if segments.empty?
  end
end
