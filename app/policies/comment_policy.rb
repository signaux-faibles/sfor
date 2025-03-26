class CommentPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.joins(establishment_tracking: { establishment: :department })
           .where(establishments: { department_id: user.department_ids })
    end
  end

  def show?
    # Si le commentaire appartient à un segment, l'utilisateur doit appartenir au même segment
    if record.segment.present?
      record.segment == user.segment && department_match?
    else
      # Si le commentaire est CODEFI (pas de segment), vérification des départements seulement
      department_match?
    end
  end

  def edit?
    user == record.user
  end

  def update?
    user == record.user
  end

  def destroy?
    user == record.user
  end

  private

  def department_match?
    # Vérifier si le département de l'établissement du commentaire est dans les départements de l'utilisateur
    record.establishment_tracking.establishment.department_id.in?(user.department_ids)
  end
end
