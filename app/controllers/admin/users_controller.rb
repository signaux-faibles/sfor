require "csv"

class Admin::UsersController < Admin::ApplicationController # rubocop:disable Metrics/ClassLength
  before_action :set_user, only: %i[show impersonate reset_password edit update destroy duplicate restore]

  def index
    @users = if params[:include_discarded] == "1"
               User.with_discarded
             else
               User.kept
             end
    @users = @users.includes(:entity, :segment, :geo_access, :networks)
    @users = @users.where("email ILIKE ?", "%#{params[:search].strip}%") if params[:search].present?
    @users = @users.order(:email)

    # Store count before pagination to avoid N+1
    @users_count = @users.count if params[:search].present?
    @users = @users.page(params[:page])
  end

  def show; end

  def new
    @user = User.new
    load_form_collections
  end

  def edit
    load_form_collections
  end

  def create
    @user = User.new(user_params)
    @user.password = User.generate_admin_password if @user.password.blank?
    @user.level ||= "A"

    if @user.save
      begin
        @user.send_reset_password_instructions
      rescue StandardError => e
        flash[:alert] = "Utilisateur créé, mais l'envoi de l'email a échoué : #{e.message}"
      end
      redirect_to admin_user_path(@user), notice: "Utilisateur créé avec succès." # rubocop:disable Rails/I18nLocaleTexts
    else
      load_form_collections
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @user.update(user_params)
      redirect_to admin_user_path(@user), notice: "Utilisateur mis à jour avec succès." # rubocop:disable Rails/I18nLocaleTexts
    else
      load_form_collections
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @user == current_user
      redirect_to admin_users_path, alert: "Vous ne pouvez pas archiver votre propre compte." # rubocop:disable Rails/I18nLocaleTexts
      return
    end

    @user.discard
    redirect_to admin_users_path, notice: "Utilisateur archivé avec succès." # rubocop:disable Rails/I18nLocaleTexts
  end

  def restore
    @user.undiscard
    redirect_to admin_user_path(@user), notice: "Utilisateur réactivé avec succès." # rubocop:disable Rails/I18nLocaleTexts
  end

  def duplicate
    source_user = @user
    @user = User.new(
      entity_id: source_user.entity_id,
      segment_id: source_user.segment_id,
      geo_access_id: source_user.geo_access_id,
      description: source_user.description,
      ambassador: source_user.ambassador,
      trained: source_user.trained,
      feedbacks: source_user.feedbacks,
      last_contact: source_user.last_contact,
      level: source_user.level
    )

    load_form_collections
    render :new
  end

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

  def import
    @created_users = []
    @failed_rows = []
  end

  def import_create
    if params[:csv_file].blank?
      redirect_to import_admin_users_path, alert: "Veuillez sélectionner un fichier CSV." # rubocop:disable Rails/I18nLocaleTexts
      return
    end

    result = Users::CsvImporter.new(params[:csv_file].read).call
    @created_users = result.created_users
    @failed_rows = result.failed_rows
    @mail_errors = result.mail_errors
    @total_rows = result.total_rows

    render :import, formats: :html
  rescue CSV::MalformedCSVError => e
    redirect_to import_admin_users_path, alert: "CSV invalide : #{e.message}"
  end

  def template # rubocop:disable Metrics/MethodLength
    headers = %w[
      email
      first_name
      last_name
      segment_name
      geo_access
      entity
      description
      ambassador
      trained
      feedbacks
      last_contact
    ]

    csv_content = CSV.generate do |csv|
      csv << headers
      csv << [
        "prenom.nom@example.com",
        "Prénom",
        "Nom",
        "crp",
        "Paris",
        "DREETS",
        "Exemple de description",
        "oui",
        "non",
        "RAS",
        "2026-02-01"
      ]
    end

    send_data csv_content, filename: "utilisateurs_template.csv", type: "text/csv"
  end

  private

  def set_user
    @user = User.with_discarded.find(params[:id])
  end

  def load_form_collections
    @entities = Entity.order(:name)
    @segments = Segment.order(:name)
    @geo_accesses = GeoAccess.order(:name)
  end

  def user_params
    params.require(:user).permit(
      :email,
      :first_name,
      :last_name,
      :segment_id,
      :geo_access_id,
      :entity_id,
      :description,
      :ambassador,
      :trained,
      :feedbacks,
      :last_contact
    )
  end
end
