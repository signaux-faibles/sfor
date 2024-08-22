class EstablishmentTrackingsController < ApplicationController
  before_action :set_establishment, except: [:new_by_siret, :index]
  before_action :set_tracking, only: %i[show destroy]

  def index
    @establishment_trackings = policy_scope(EstablishmentTracking).includes(:establishment, :referents, :tracking_labels).page(params[:page])
  end
  def show
  end

  def new
    @establishment_tracking = @establishment.establishment_trackings.new
    @establishment_tracking.referents << current_user
  end

  def new_by_siret
    @establishment = Establishment.find_by(siret: params[:siret])
    if @establishment
      redirect_to new_establishment_establishment_tracking_path(@establishment)
    else
      redirect_to root_path, alert: 'Impossible de trouver l\'établissement'
    end
  end

  def create
    @establishment_tracking = @establishment.establishment_trackings.new(tracking_params)
    @establishment_tracking.creator = current_user

    if @establishment_tracking.save
      redirect_to @establishment, notice: 'L\'accompagnement a été créé avec succès.'
    else
      puts @establishment_tracking.errors.inspect
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @establishment = @establishment_tracking.establishment
    @establishment_tracking.destroy
    redirect_to @establishment, notice: 'L\'accompagnement a été supprimé avec succès.'
  end

  private

  def set_establishment
    @establishment = Establishment.find(params[:establishment_id])
  end

  def set_tracking
    @establishment_tracking = EstablishmentTracking.find(params[:id])
  end

  def tracking_params
    params.require(:establishment_tracking).permit(:status, participant_ids: [], referent_ids: [], tracking_label_ids: [])
  end
end