class ApplicationController < ActionController::Base
  impersonates :user
  around_action :set_time_zone
  before_action :check_maintenance_mode
  before_action :authenticate_user!, unless: :devise_controller?
  before_action :set_notification_flash
  before_action :check_user_segment
  before_action :set_sentry_user
  after_action :track_action

  include Pundit::Authorization

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  layout :layout_by_resource
  helper_method :unread_notifications_count

  private

  def check_maintenance_mode
    # Allow health check, Devise flows (login, password reset, etc.) and admin
    return if devise_controller?
    return if controller_path == "users/two_factor"
    return if request.path.start_with?("/admin")
    return if request.path == "/up"

    return unless AppSetting.current&.maintenance_mode?

    render file: Rails.public_path.join("maintenance.html"),
           layout: false,
           status: :service_unavailable
  end

  def set_notification_flash
    return unless user_signed_in?
    return if request.path.start_with?("/admin")

    notification = Notification.for_user(current_user)
                               .where.not(show_as_flash: [nil, ""])
                               .unread_for_user(current_user)
                               .order(created_at: :desc)
                               .first
    return unless notification

    flash_type = notification.show_as_flash
    message = "#{notification.title} #{view_context.link_to('Voir', notification_path(notification), class: 'fr-link')}"

    Rails.logger.info("Notification flash: #{flash_type} - #{message}")
    flash.now[flash_type.to_sym] = message.html_safe
  end

  def layout_by_resource
    if devise_controller?
      "devise"
    else
      "application"
    end
  end

  def user_not_authorized
    respond_to do |format|
      format.turbo_stream do
        flash_html = "<div class='fr-alert fr-alert--error' aria-live='polite'>#{t('unauthorized.access_denied')}</div>".html_safe
        render turbo_stream: turbo_stream.replace("flash", html: flash_html),
               status: :forbidden
      end
      format.html do
        flash[:alert] = t("unauthorized.action_not_allowed")
        redirect_back(fallback_location: root_path)
      end
    end
  end

  def check_user_segment
    return if devise_controller? || request.path == unauthorized_path

    redirect_to unauthorized_path, alert: t("unauthorized.section_not_allowed") if current_user && current_user.segment.name == "sf"
  end

  def unread_notifications_count
    return 0 unless current_user

    @unread_notifications_count ||= current_user.unread_notifications_count
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

  def track_action
    return if Rails.env.development?

    name = "#{controller_name}##{action_name}"
    ahoy.track name, request.path_parameters
  end
end
