class Admin::ApplicationController < ApplicationController
  skip_before_action :check_user_segment
  before_action :authenticate_admin

  layout "admin/application"

  private

  def authenticate_admin
    unless current_user && current_user.segment.name == "sf"
      flash[:alert] = t("admin.application.unauthorized")
      redirect_to root_url
    end
  end
end
