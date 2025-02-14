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
    record.establishment.department_id.in?(user.department_ids)
  end
end