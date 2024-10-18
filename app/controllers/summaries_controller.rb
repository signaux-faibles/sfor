class SummariesController < ApplicationController
  before_action :set_establishment_and_tracking

  def create
    @summary = @establishment_tracking.summaries.new(summary_params)

    unless @summary.is_codefi
      @summary.segment = current_user.segment
    end

    if @summary.save
      flash.now[:notice] = "Synthèse créée avec succès."
    else
      render turbo_stream: turbo_stream.update(@summary.is_codefi ? "codefi_summary" : "segment_summary",
                                               partial: "summaries/form",
                                               locals: { summary: @summary, is_codefi: params[:summary][:is_codefi] == "true" },
                                               status: :unprocessable_entity)
    end
  end

  def edit
    @summary = @establishment_tracking.summaries.find(params[:id])

    if @summary.locked? && @summary.locked_by != current_user.id
      render turbo_stream: turbo_stream.update(@summary.is_codefi ? "codefi_summary" : "segment_summary",
                                               partial: "summaries/summary",
                                               locals: { summary: @summary, is_codefi: @summary.is_codefi, establishment: @establishment, establishment_tracking: @establishment_tracking },
      )
    else
      @summary.lock!(current_user)
    end
  end

  def update
    @summary = @establishment_tracking.summaries.find(params[:id])
    @summary.unlock!

    if @summary.update(summary_params)
      flash.now[:notice] = "Synthèse modifiée avec succès."
    else
      render turbo_stream: turbo_stream.update(@summary.is_codefi ? "codefi_summary" : "segment_summary",
                                               partial: "summaries/form",
                                               locals: { summary: @summary, is_codefi: @summary.is_codefi },
                                               status: :unprocessable_entity
      )
    end
  end

  def cancel
    @summary = @establishment_tracking.summaries.find(params[:id])
    @summary.unlock!
    flash.now[:notice] = "Modification annulée."
  end

  private

  def set_establishment_and_tracking
    @establishment = Establishment.find(params[:establishment_id])
    @establishment_tracking = @establishment.establishment_trackings.find(params[:establishment_tracking_id])
  end

  def summary_params
    params.require(:summary).permit(:content, :is_codefi, :segment_id)
  end
end