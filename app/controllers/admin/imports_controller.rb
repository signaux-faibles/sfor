# frozen_string_literal: true

class Admin::ImportsController < Admin::ApplicationController
  before_action :set_import, only: %i[edit update destroy]

  def index
    @imports = Import.order(import_date: :desc).page(params[:page])
  end

  def new
    @import = Import.new
  end

  def edit; end

  def create
    @import = Import.new(import_params)
    if @import.save
      redirect_to admin_imports_path, notice: "L'import a été créé avec succès." # rubocop:disable Rails/I18nLocaleTexts
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @import.update(import_params)
      redirect_to admin_imports_path, notice: "L'import a été mis à jour avec succès." # rubocop:disable Rails/I18nLocaleTexts
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @import.destroy
    redirect_to admin_imports_path, notice: "L'import a été supprimé." # rubocop:disable Rails/I18nLocaleTexts
  end

  private

  def set_import
    @import = Import.find(params[:id])
  end

  def import_params
    params.require(:import).permit(:name, :import_date, :data_freshness)
  end
end
