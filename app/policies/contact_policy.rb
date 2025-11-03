class ContactPolicy < ApplicationPolicy
  def create?
    department_match?
  end

  def edit?
    department_match?
  end

  def update?
    department_match?
  end

  def destroy?
    department_match?
  end

  private

  def department_match?
    return false unless record.establishment&.departement

    user.departments.pluck(:code).include?(record.establishment.departement)
  end
end
