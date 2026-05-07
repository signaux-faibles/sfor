class CommentsController < ApplicationController
  include EstablishmentTrackings::Notifiable

  before_action :set_establishment_and_tracking
  before_action :set_comment, only: %i[edit update destroy]
  before_action :authorize_comment, only: %i[edit update destroy]

  before_action :set_paper_trail_whodunnit

  def edit; end

  def create
    @comment = build_comment
    if @comment.save
      notify_referents_tracking_updated(
        modified_by: current_user,
        tracking: @establishment_tracking,
        network_ids: [@comment.network_id]
      )
      flash.now[:notice] = t(".success")
    else
      render turbo_stream: turbo_stream.update("new_comment_#{@comment.network.name.parameterize}",
                                               partial: "comments/form",
                                               locals: { comment: @comment, network: @comment.network },
                                               status: :unprocessable_entity)
    end
  end

  def update
    if @comment.update(comment_params)
      flash.now[:notice] = t(".success")
    else
      render turbo_stream: turbo_stream.update("comment_#{@comment.id}",
                                               partial: "comments/form",
                                               locals: { comment: @comment, network: @comment.network },
                                               status: :unprocessable_entity) end
  end

  def destroy
    network_id = @comment.network_id
    if @comment.destroy
      notify_referents_tracking_updated(
        modified_by: current_user,
        tracking: @establishment_tracking,
        network_ids: [network_id]
      )
    end
    flash.now[:notice] = t(".success")
  end

  private

  def set_establishment_and_tracking
    @establishment = Establishment.find_by!(siret: params[:establishment_siret])
    @establishment_tracking = @establishment.establishment_trackings.find(params[:establishment_tracking_id])
  end

  def set_comment
    @comment = @establishment_tracking.comments.find(params[:id])
  end

  def authorize_comment
    authorize @comment
  end

  def comment_params
    params.expect(comment: %i[content network_id])
  end

  def build_comment
    comment = @establishment_tracking.comments.new(comment_params)
    comment.user = current_user
    comment.network ||= current_user.networks.where.not(name: "codefi").first
    comment
  end
end
