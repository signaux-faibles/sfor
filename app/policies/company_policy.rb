class CompanyPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(department: user.departments.pluck(:code))
    end
  end
end
