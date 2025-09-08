class SummariesController < ApplicationController
  before_action :set_establishment_and_tracking

  before_action :set_paper_trail_whodunnit

  def edit
    @summary = @establishment_tracking.summaries.find(params[:id])
    authorize @establishment_tracking, :edit?

    if @summary.locked? && @summary.locked_by != current_user.id
      render_summary_view
    else
      @summary.lock!(current_user)
    end
  end

  def create
    @summary = @establishment_tracking.summaries.new(summary_params)
    assign_network unless @summary.network

    if @summary.save
      flash.now[:notice] = t(".success")
    else
      render_summary_form
    end
  end

  def update
    @summary = @establishment_tracking.summaries.find(params[:id])
    @summary.unlock!

    if @summary.update(summary_params)
      flash.now[:notice] = t(".success")
    else
      render_summary_form
    end
  end

  def cancel
    @summary = @establishment_tracking.summaries.find(params[:id])
    @summary.unlock!
    flash.now[:notice] = t(".success")
  end

  private

  def set_establishment_and_tracking
    @establishment = Establishment.find_by!(siret: params[:establishment_siret])
    @establishment_tracking = @establishment.establishment_trackings.find(params[:establishment_tracking_id])
  end

  def summary_params
    params.require(:summary).permit(:content, :network_id)
  end

  def assign_network
    @summary.network = current_user.networks.where.not(name: "codefi").first
  end

  def render_summary_form
    render turbo_stream: turbo_stream.update(
      "#{@summary.network.name.parameterize}_summary",
      partial: "summaries/form",
      locals: { summary: @summary, network: @summary.network },
      status: :unprocessable_entity
    )
  end

  def render_summary_view
    render turbo_stream: turbo_stream.update(
      "#{@summary.network.name.parameterize}_summary",
      partial: "summaries/summary",
      locals: {
        summary: @summary,
        establishment: @establishment,
        establishment_tracking: @establishment_tracking,
        network: @summary.network
      }
    )
  end
end
