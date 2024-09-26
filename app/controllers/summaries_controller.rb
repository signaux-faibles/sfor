class SummariesController < ApplicationController
  before_action :set_establishment_and_tracking

  def create
    @summary = @establishment_tracking.summaries.new(summary_params)

    puts summary_params.inspect

    puts "On créer bien le Summary"
    puts @summary.inspect
    puts @summary.is_codefi
    unless @summary.is_codefi
      puts "On attribue le summary on segment du user"
      @summary.segment = current_user.segment
      puts @summary.segment.inspect
    end

    if @summary.save
      puts "On a bien réussi à save"
      puts @summary.is_codefi
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
  end

  def update
    @summary = @establishment_tracking.summaries.find(params[:id])
    if @summary.update(summary_params)
      flash.now[:notice] = "Synthèse modifiée avec succès."
    else
      render turbo_stream: turbo_stream.update(@summary.is_codefi ? "codefi_summary" : "segment_summary",
                                               partial: "summaries/form",
                                               locals: { summary: @summary, is_codefi: @summary.is_codefi },
                                               status: :unprocessable_entity)
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