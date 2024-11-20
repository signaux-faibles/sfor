class ApplicationController < ActionController::Base
  impersonates :user
  before_action :authenticate_user!
  before_action :check_user_segment
  include Pundit::Authorization

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private
  def user_not_authorized
    flash[:alert] = "Vous n'êtes pas autorisé à effectuer cette action."
    redirect_back(fallback_location: root_path)
  end

  def check_user_segment
    return if devise_controller? || request.path == unauthorized_path

    if current_user && !%w[crp dreets_reseaucrp].include?(current_user.segment.name)
      redirect_to unauthorized_path, alert: "Vous n'êtes pas autorisé à accéder à cette section."
    end
  end
end
