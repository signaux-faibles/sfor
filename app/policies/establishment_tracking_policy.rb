class EstablishmentTrackingPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.joins(:establishment).where(establishments: { department_id: user.department_id })
    end
  end
end