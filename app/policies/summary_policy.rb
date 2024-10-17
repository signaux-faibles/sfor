class SummaryPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.joins(establishment_tracking: { establishment: :department })
           .where(establishments: { department_id: user.department_ids })
    end
  end

  def show?
    record_matches_user_segment_and_department?
  end

  def create?
    record_matches_user_segment_and_department?
  end

  def update?
    record_matches_user_segment_and_department?
  end

  def edit?
    record_matches_user_segment_and_department?
  end

  def cancel?
    record_matches_user_segment_and_department?
  end

  private

  def record_matches_user_segment_and_department?
    if record.segment.present?
      record.segment == user.segment && department_match?
    else
      department_match?
    end
  end

  def department_match?
    record.establishment_tracking.establishment.department_id.in?(user.department_ids)
  end
end