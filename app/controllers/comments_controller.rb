class CommentsController < ApplicationController
  before_action :set_establishment_and_tracking
  before_action :set_comment, only: [:edit, :update, :destroy]
  before_action :authorize_comment, only: [:edit, :update, :destroy]

  def create
    @comment = @establishment_tracking.comments.new(comment_params)
    @comment.user = current_user

    if params[:comment][:is_codefi] == "true"
      @comment.segment = nil
    else
      @comment.segment = current_user.segment
    end

    if @comment.save
      puts "ON SAVE"
      flash.now[:notice] = "Commentaire ajouté avec succès."
    else
      render turbo_stream: turbo_stream.replace("new_comment_#{params[:comment][:is_codefi] == 'true' ? 'codefi' : 'segment'}",
                                                partial: "comments/form",
                                                locals: { comment: @comment, is_codefi: params[:comment][:is_codefi] == "true" },
                                                status: :unprocessable_entity)
    end
  end

  def edit
    # Pas de besoin de rendre explicitement quoi que ce soit ici, Turbo gérera automatiquement le template `edit.turbo_stream.erb`.
  end

  def update
    if @comment.update(comment_params)
      flash.now[:notice] = "Commentaire mis à jour avec succès."
    else
      render :update, status: :unprocessable_entity
    end
  end

  def destroy
    @comment.destroy
    flash.now[:notice] = "Commentaire supprimé avec succès."
  end

  private

  def set_establishment_and_tracking
    @establishment = Establishment.find(params[:establishment_id])
    @establishment_tracking = @establishment.establishment_trackings.find(params[:establishment_tracking_id])
  end

  def set_comment
    @comment = @establishment_tracking.comments.find(params[:id])
  end

  def authorize_comment
    authorize @comment
  end

  def comment_params
    params.require(:comment).permit(:content, :is_codefi, :segment_id)
  end
end