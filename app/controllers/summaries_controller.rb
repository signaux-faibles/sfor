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
      render turbo_stream: turbo_stream.replace("new_summary", partial: "summaries/form", locals: { summary: @summary })
    end
  end

  def edit
    @summary = @establishment_tracking.summaries.find(params[:id])
  end

  def update
    @summary = @establishment_tracking.summaries.find(params[:id])
    if @summary.update(summary_params)
      flash.now[:notice] = "Synthèse modifiée avec succès."
    else
      render turbo_stream: turbo_stream.replace(dom_id(@summary), partial: "summaries/form", locals: { summary: @summary })
    end
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