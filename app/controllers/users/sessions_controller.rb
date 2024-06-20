class Users::SessionsController < Devise::SessionsController
  def new
    respond_to do |format|
      format.html { render 'users/sessions/new' }
    end
  end
end
