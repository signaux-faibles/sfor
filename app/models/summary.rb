class Summary < ApplicationRecord
  belongs_to :establishment_tracking
  belongs_to :segment, optional: true

  validates :content, presence: true
  validate :ensure_unique_codefi_summary

  private

  def ensure_unique_codefi_summary
    if is_codefi && Summary.where(establishment_tracking_id: establishment_tracking_id, is_codefi: true).where.not(id: id).exists?
      errors.add(:base, "Il ne peut y avoir qu'une seule synthèse CODEFI par accompagnement.")
    end
  end
end