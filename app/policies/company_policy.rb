class CompanyPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.joins(:establishments)
           .where(establishments: { siege: true, departement: user.departments.pluck(:code) })
           .distinct
    end
  end
end
