class ContactsController < ApplicationController
  before_action :set_establishment
  before_action :set_establishment_tracking
  before_action :set_contact, only: %i[edit update destroy archive]
  before_action :authorize_contact, only: %i[edit update destroy]

  def new
    @contact = @establishment.contacts.new
  end

  def edit; end

  def create
    @contact = @establishment.contacts.new(contact_params)
    authorize @contact

    if @contact.save
      redirect_to establishment_establishment_tracking_path(@establishment, @establishment_tracking),
                  notice: t(".success")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @contact.update(contact_params)
      redirect_to establishment_establishment_tracking_path(@establishment, @establishment_tracking),
                  notice: t(".success")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def archive
    @contact.discard
    redirect_to establishment_establishment_tracking_path(@establishment, @establishment_tracking),
                notice: t("contacts.destroy.success")
  end

  def destroy
    @contact.destroy
    redirect_to establishment_establishment_tracking_path(@establishment, @establishment_tracking),
                notice: t(".success")
  end

  private

  def set_establishment
    @establishment = Establishment.find_by!(siret: params[:establishment_siret])
  end

  def set_establishment_tracking
    @establishment_tracking = EstablishmentTracking.find(params[:establishment_tracking_id])
  end

  def set_contact
    @contact = @establishment.contacts.find(params[:id])
  end

  def authorize_contact
    authorize @contact
  end

  def contact_params
    params.require(:contact).permit(:first_name, :last_name, :role, :phone_number_primary, :phone_number_secondary,
                                    :email, :description)
  end
end
