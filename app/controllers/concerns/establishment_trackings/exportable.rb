# frozen_string_literal: true

# Handles export functionality for establishment trackings
module EstablishmentTrackings::Exportable
  extend ActiveSupport::Concern

  private

  def generate_excel(establishment_trackings, filters)
    EstablishmentTrackingExcelGenerator.new(establishment_trackings, filters, current_user).generate
  end

  def export_establishment_trackings(establishment_trackings, query)
    all_establishment_trackings = establishment_trackings.includes(:establishment, :referents)
    response.headers["Cache-Control"] = "no-store"
    send_data generate_excel(all_establishment_trackings, query),
              filename: "accompagnements.xlsx",
              type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
              disposition: "attachment"
  end
end
