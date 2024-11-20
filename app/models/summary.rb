class Summary < ApplicationRecord
  has_paper_trail

  belongs_to :establishment_tracking
  belongs_to :network, optional: false
  belongs_to :locked_by_user, class_name: 'User', foreign_key: 'locked_by', optional: true

  validates :content, presence: true
  validates :network_id, presence: true
  validates :establishment_tracking_id, uniqueness: { scope: :network_id }
  def lock!(user)
    update!(locked_by: user.id, locked_at: Time.current)
  end

  def unlock!
    update!(locked_by: nil, locked_at: nil)
  end

  def locked?
    locked_at.present? && locked_at > 2.hours.ago
  end

  def locked_by_user?
    locked? && locked_by_user.present?
  end

  private
end