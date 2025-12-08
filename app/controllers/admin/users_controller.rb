class Admin::UsersController < Admin::ApplicationController
  before_action :set_user, only: %i[show impersonate reset_password]

  def index
    @users = User.includes(:entity, :segment)
    @users = @users.where("email ILIKE ?", "%#{params[:search].strip}%") if params[:search].present?
    @users = @users.order(:email)

    # Store count before pagination to avoid N+1
    @users_count = @users.count if params[:search].present?
    @users = @users.page(params[:page])
  end

  def show; end

  def impersonate
    if @user == current_user
      redirect_to admin_users_path, alert: "Vous ne pouvez pas vous imiter vous-même" # rubocop:disable Rails/I18nLocaleTexts
    else
      impersonate_user(@user)
      redirect_to root_path, notice: "Vous êtes maintenant connecté en tant que #{@user.email}"
    end
  end

  def reset_password
    # Generate a reset password token without sending email
    raw_token = @user.send(:set_reset_password_token)
    reset_url = edit_user_password_url(reset_password_token: raw_token)
    flash[:reset_password_url] = reset_url
    redirect_to admin_user_path(@user),
                notice: "Lien de réinitialisation généré. Vous pouvez le copier depuis la page de l'utilisateur." # rubocop:disable Rails/I18nLocaleTexts
  end

  private

  def set_user
    @user = User.find(params[:id])
  end
end
