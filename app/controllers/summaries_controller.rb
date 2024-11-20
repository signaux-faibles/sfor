class SummariesController < ApplicationController
  before_action :set_establishment_and_tracking

  def create
    @summary = @establishment_tracking.summaries.new(summary_params)

    if @summary.network.nil?
      @summary.network = current_user.networks.where.not(name: 'codefi').first
    end

    if @summary.save
      flash.now[:notice] = "Synthèse créée avec succès."
    else
      render turbo_stream: turbo_stream.update("#{@summary.network.name.parameterize}_summary",
                                               partial: "summaries/form",
                                               locals: { summary: @summary, network: @summary.network },
                                               status: :unprocessable_entity)
    end
  end

  def edit
    @summary = @establishment_tracking.summaries.find(params[:id])

    if @summary.locked? && @summary.locked_by != current_user.id
      render turbo_stream: turbo_stream.update("#{@summary.network.name.parameterize}_summary",
                                               partial: "summaries/summary",
                                               locals: { summary: @summary, establishment: @establishment, establishment_tracking: @establishment_tracking, network: @summary.network },
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
      render turbo_stream: turbo_stream.update("#{@summary.network.name.parameterize}_summary",
                                               partial: "summaries/form",
                                               locals: { summary: @summary, network: @summary.network },
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
    params.require(:summary).permit(:content, :network_id)
  end
end