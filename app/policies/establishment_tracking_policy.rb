class EstablishmentTrackingPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.joins(establishment: :department)
           .where(establishments: { department_id: user.department_ids })
    end
  end
end