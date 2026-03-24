class Admin::NotificationsController < Admin::ApplicationController
  before_action :set_notification, only: %i[show edit update destroy]
  before_action :set_segments, only: %i[new edit create update]

  def index
    @notifications = Notification.order(updated_at: :desc).includes(:segments, :created_by)
  end

  def show; end

  def new
    @notification = Notification.new
  end

  def edit; end

  def create
    @notification = Notification.new(notification_params)
    @notification.created_by = current_user

    if @notification.save
      redirect_to admin_notification_path(@notification),
                  notice: "La notification a été créée." # rubocop:disable Rails/I18nLocaleTexts
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @notification.update(notification_params)
      redirect_to admin_notification_path(@notification),
                  notice: "La notification a été mise à jour." # rubocop:disable Rails/I18nLocaleTexts
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @notification.destroy
    redirect_to admin_notifications_path,
                notice: "La notification a été supprimée." # rubocop:disable Rails/I18nLocaleTexts
  end

  private

  def set_notification
    @notification = Notification.find(params[:id])
  end

  def set_segments
    @segments = Segment.order(:name)
  end

  def notification_params
    params.require(:notification).permit(:title, :body, :show_as_flash, segment_ids: [])
  end
end
