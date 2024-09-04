class EstablishmentTrackingPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.joins(establishment: :department)
           .where(establishments: { department_id: user.department_ids })
    end
  end

  def show?
    user.department_ids.include?(record.establishment.department.id)
  end

  def destroy?
    user.department_ids.include?(record.establishment.department.id)
  end
end