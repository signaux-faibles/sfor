# frozen_string_literal: true

class Admin::AppSettingsController < Admin::ApplicationController
  before_action :set_app_setting, only: %i[show edit update destroy]

  def index
    @app_settings = AppSetting.order(updated_at: :desc)
  end

  def show; end

  def new
    existing = AppSetting.current
    return redirect_to admin_app_setting_path(existing) if existing

    @app_setting = AppSetting.new
  end

  def edit; end

  def create
    existing = AppSetting.current
    return redirect_to admin_app_setting_path(existing) if existing

    @app_setting = AppSetting.new(app_setting_params)
    if @app_setting.save
      redirect_to admin_app_setting_path(@app_setting),
                  notice: "Les paramètres ont été créés." # rubocop:disable Rails/I18nLocaleTexts
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @app_setting.update(app_setting_params)
      redirect_to admin_app_setting_path(@app_setting),
                  notice: "Les paramètres ont été mis à jour." # rubocop:disable Rails/I18nLocaleTexts
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @app_setting.destroy
    redirect_to admin_app_settings_path, notice: "Les paramètres ont été supprimés." # rubocop:disable Rails/I18nLocaleTexts
  end

  private

  def set_app_setting
    @app_setting = AppSetting.find(params[:id])
  end

  def app_setting_params
    params.require(:app_setting).permit(:entreprises_recentes_filter_date)
  end
end
