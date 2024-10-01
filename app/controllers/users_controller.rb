class UsersController < ApplicationController
  def stop_impersonating
    authorize current_user
    stop_impersonating_user
    redirect_to admin_root_path
  end
end