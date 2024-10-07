class Summary < ApplicationRecord
  has_paper_trail

  belongs_to :establishment_tracking
  belongs_to :segment, optional: true

  validates :content, presence: true
  validate :ensure_unique_codefi_or_segment_summary

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