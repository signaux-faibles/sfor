class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  include Pundit::Authorization

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private
  def user_not_authorized(exception)
    policy_name = exception.policy.class.to_s.underscore

    flash[:alert] = "Vous n'êtes pas autorisé à effectuer cette action."
    redirect_back(fallback_location: root_path)
  end
end
