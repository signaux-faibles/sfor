class UserPolicy < ApplicationPolicy
  def stop_impersonating?
    true
  end
end
