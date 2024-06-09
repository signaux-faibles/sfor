class EstablishmentsController < ApplicationController
  before_action :set_establishment, only: %i[show follow unfollow]

  def index
    @establishments = Establishment.all
  end

  def show
  end

  def my_establishments
    @establishments = current_user.establishments
  end

  def follow
    establishment = Establishment.find(params[:id])
    current_user.establishment_followers.create!(establishment: establishment, status: 'in progress')

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace('follow_button', partial: 'establishments/unfollow', locals: { establishment: establishment }) }
      format.html { redirect_to @establishment }
    end
  end

  def unfollow
    establishment = Establishment.find(params[:id])
    current_user.establishments.delete(@establishment)

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace('follow_button', partial: 'establishments/follow', locals: { establishment: establishment }) }
      format.html { redirect_to @establishment }
    end
  end

  private

  def set_establishment
    @establishment = Establishment.find(params[:id])
  end
end