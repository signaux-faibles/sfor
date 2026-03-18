class NotificationsController < ApplicationController
  def index
    @notifications = Notification.for_user(current_user).order(created_at: :desc)
    notification_ids = @notifications.reselect(:id).unscope(:order)
    @notification_reads = current_user.notification_reads.where(notification_id: notification_ids)
                                      .index_by(&:notification_id)
  end

  def show
    @notification = Notification.for_user(current_user).find(params[:id])
    @notification_read = current_user.notification_reads.find_or_initialize_by(notification: @notification)

    @notification_read.update(read_at: Time.current) if @notification_read.read_at.nil?
  end
end
