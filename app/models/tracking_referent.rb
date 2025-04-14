class TrackingReferent < ApplicationRecord
  belongs_to :establishment_tracking
  belongs_to :user

  validate :must_have_at_least_one_active_referent, on: :destroy

  private

  def must_have_at_least_one_active_referent
    return if establishment_tracking.referents.kept.count > 1

    errors.add(:base, :must_have_at_least_one_active_referent)
  end
end
