class Summary < ApplicationRecord
  has_paper_trail

  belongs_to :establishment_tracking
  belongs_to :segment, optional: true
  belongs_to :locked_by_user, class_name: 'User', foreign_key: 'locked_by', optional: true

  validates :content, presence: true
  validate :ensure_unique_codefi_or_segment_summary

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

  def ensure_unique_codefi_or_segment_summary
    # Check for CODEFI summary (where segment_id is nil)
    if segment_id.nil? && Summary.where(establishment_tracking_id: establishment_tracking_id, segment_id: nil).where.not(id: id).exists?
      errors.add(:base, "Il ne peut y avoir qu'une seule synthèse CODEFI (sans segment) par accompagnement.")
    end

    # Check for unique summary per segment (crp, urssaf,...)
    if segment_id.present? && Summary.where(establishment_tracking_id: establishment_tracking_id, segment_id: segment_id).where.not(id: id).exists?
      errors.add(:base, "Il ne peut y avoir qu'une seule synthèse par segment pour cet accompagnement.")
    end
  end
end