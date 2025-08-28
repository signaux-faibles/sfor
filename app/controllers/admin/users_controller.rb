class Admin::UsersController < Admin::ApplicationController
  before_action :set_user, only: %i[show impersonate]

  def index
    @users = User.includes(:entity, :segment)
    @users = @users.where("email ILIKE ?", "%#{params[:search].strip}%") if params[:search].present?
    @users = @users.order(:email)

    # Store count before pagination to avoid N+1
    @users_count = @users.count if params[:search].present?
    @users = @users.page(params[:page])
  end

  def show
  end

  def impersonate
    if @user == current_user
      redirect_to admin_users_path, alert: "Vous ne pouvez pas vous imiter vous-même"
    else
      impersonate_user(@user)
      redirect_to root_path, notice: "Vous êtes maintenant connecté en tant que #{@user.email}"
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end
end
