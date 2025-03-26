class ApplicationController < ActionController::Base
  impersonates :user
  around_action :set_time_zone
  before_action :authenticate_user!
  before_action :check_user_segment
  before_action :set_sentry_user

  include Pundit::Authorization

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def user_not_authorized
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("flash", html: "<div class='fr-alert fr-alert--error'>Accès interdit.</div>".html_safe),
               status: :forbidden
      end
      format.html do
        flash[:alert] = "Vous n'êtes pas autorisé à effectuer cette action."
        redirect_back(fallback_location: root_path)
      end
    end
  end

  def check_user_segment
    return if devise_controller? || request.path == unauthorized_path

    if current_user && current_user.segment.name == "sf"
      redirect_to unauthorized_path, alert: "Vous n'êtes pas autorisé à accéder à cette section."
    end
  end

  def set_time_zone(&)
    Time.use_zone(current_user&.time_zone || "Paris", &)
  end

  def set_sentry_user
    if user_signed_in?
      Sentry.set_user(
        email: current_user.email
      )
    else
      Sentry.set_user({})
    end
  end
end
