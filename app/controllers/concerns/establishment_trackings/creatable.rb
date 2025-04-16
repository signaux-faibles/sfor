# frozen_string_literal: true

# Handles establishment creation functionality
module EstablishmentTrackings::Creatable
  extend ActiveSupport::Concern

  private

  def handle_existing_establishment
    active_tracking = @establishment.establishment_trackings.find_by(state: %w[in_progress under_surveillance])
    if active_tracking
      redirect_to establishment_establishment_tracking_path(@establishment, active_tracking),
                  alert: t("establishments.tracking.active_exists")
    else
      redirect_to new_establishment_establishment_tracking_path(@establishment)
    end
  end

  def create_new_establishment
    department = find_department
    return unless department

    siren = params[:siret][0, 9]
    create_establishment_with_company(department, siren)
  end

  def find_department
    department = Department.find_by(code: params[:code_departement])
    unless department
      redirect_to root_path, alert: t("establishments.tracking.department_not_found", code: params[:code_departement])
      return nil
    end
    department
  end

  def create_establishment_with_company(department, siren)
    ActiveRecord::Base.transaction do
      company = find_or_create_company(siren, department)
      create_establishment(company, department, siren)
    end
  rescue ActiveRecord::RecordInvalid => e
    redirect_to root_path,
                alert: t("establishments.tracking.creation_error", errors: e.record.errors.full_messages.join(", "))
  end

  def find_or_create_company(siren, department)
    Company.find_or_create_by!(siren: siren) do |c|
      c.siret = params[:siret]
      c.department_id = department.id
    end
  end

  def create_establishment(company, department, siren)
    @establishment = Establishment.new(siret: params[:siret],
                                       raison_sociale: params[:denomination],
                                       siren: siren,
                                       department: department,
                                       company: company)

    redirect_to new_establishment_establishment_tracking_path(@establishment) if @establishment.save
  end
end
