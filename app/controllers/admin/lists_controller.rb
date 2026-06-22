# frozen_string_literal: true

class Admin::ListsController < Admin::ApplicationController
  before_action :set_list, only: %i[edit update]

  def index
    @lists = List.latest_first
  end

  def edit; end

  def update
    if @list.update(list_params)
      redirect_to admin_lists_path, notice: "La liste a ete mise a jour." # rubocop:disable Rails/I18nLocaleTexts
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_list
    @list = List.find(params[:id])
  end

  def list_params
    params.expect(list: %i[precision_alerte_elevee precision_alerte_moderee])
  end
end
