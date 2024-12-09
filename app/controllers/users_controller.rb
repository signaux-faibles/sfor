class UsersController < ApplicationController
  around_action :set_time_zone, except: [:stop_impersonating]
  def stop_impersonating
    authorize current_user
    stop_impersonating_user
    redirect_to admin_root_path
  end

  def set_time_zone
    if current_user && params[:time_zone].present?
      current_user.update(time_zone: params[:time_zone])
      head :ok
    else
      head :unprocessable_entity
    end
  end
end