class EstablishmentTrackingPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.joins(establishment: :department)
           .where(establishments: { department_id: user.department_ids })
    end
  end

  def show?
    user.department_ids.include?(record.establishment.department.id) || user_is_referent_or_participant?
  end

  # Users must be able to view the record AND be a referent or participant to edit it
  def update?
    show? && user_is_referent_or_participant?
  end

  def edit?
    show? && user_is_referent_or_participant?
  end

  def destroy?
    show? && user_is_referent_or_participant?
  end

  def manage_contributors?
    show?
  end

  def update_contributors?
    show?
  end

  def manage_state?
    user_is_referent? # Only referents can manage the state
  end

  private

  def user_is_referent_or_participant?
    user_is_referent? || user_is_participant?
  end

  def user_is_referent?
    record.referents.include?(user)
  end

  def user_is_participant?
    record.participants.include?(user)
  end
end
