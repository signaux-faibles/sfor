class CompanyPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      # If user has access to all departments (France entière), skip filtering
      return scope if user.geo_access.name.downcase == "france entière"

      # Otherwise, filter by user's departments
      scope.where(department: user.departments.pluck(:code))
    end
  end
end
