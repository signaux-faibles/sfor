class EstablishmentFollowerController < ApplicationController
  def create
    @establishment_follower = EstablishmentFollower.new(user: current_user, establishment_id: params[:establishment_id], start_date: DateTime.now, status: 'in progress')
    if @establishment_follower.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to establishments_path }
      end
    else
      # handle validation errors...
    end
  end

  def destroy
    @establishment_follower = EstablishmentFollower.find(params[:id])
    @establishment_follower.destroy
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to establishments_path }
    end
  end
end
