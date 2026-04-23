class Admin::ZonesController < Admin::ApplicationController
  before_action :set_zone, only: %i[edit update]

  def index
    @zones = Zone.order(:key)
  end

  def new
    @zone = Zone.new
  end

  def edit; end

  def create
    @zone = Zone.new(zone_params)
    if @zone.save
      redirect_to admin_zones_path, notice: "La zone a ete creee." # rubocop:disable Rails/I18nLocaleTexts
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @zone.update(zone_params)
      redirect_to admin_zones_path, notice: "La zone a ete mise a jour." # rubocop:disable Rails/I18nLocaleTexts
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_zone
    @zone = Zone.find(params[:id])
  end

  def zone_params
    params.require(:zone).permit(:key, :content)
  end
end
