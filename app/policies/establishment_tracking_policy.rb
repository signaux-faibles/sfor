class EstablishmentTrackingPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.joins(:establishment)
           .where(establishments: { departement: user.departments.pluck(:code) })
    end
  end

  def show?
    user.department_ids.include?(record.establishment.department&.id) || user_is_referent_or_participant?
  end

  def create?
    user.department_ids.include?(record.establishment.department&.id) && establishment_has_no_active_tracking?
  end

  # Users must be able to view the record AND be a referent or participant to edit it
  def update?
    show? && user_is_referent_or_participant? && !record.completed?
  end

  def edit?
    show? && user_is_referent_or_participant? && !record.completed?
  end

  def destroy?
    show? && user_is_referent_or_participant?
  end

  def manage_contributors?
    show? && !record.completed?
  end

  def update_contributors?
    show?
  end

  def remove_referent?
    show?
  end

  def remove_participant?
    show?
  end

  def manage_state?
    user_is_referent?
  end

  def confirm?
    user_is_referent?
  end

  def complete?
    user_is_referent?
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

  def establishment_has_no_active_tracking?
    record.establishment.establishment_trackings.where(state: %w[in_progress under_surveillance]).none?
  end
end
