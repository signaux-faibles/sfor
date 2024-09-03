class SummaryPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.joins(establishment_tracking: { establishment: :department })
           .where(establishments: { department_id: user.department_ids })
    end
  end

  def show?
    if record.segment.present?
      record.segment == user.segment && department_match?
    else
      department_match?
    end
  end

  private

  def department_match?
    record.establishment_tracking.establishment.department_id.in?(user.department_ids)
  end
end