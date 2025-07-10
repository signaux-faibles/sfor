# frozen_string_literal: true

module EstablishmentTrackings::SupportingServicesTrackable
  extend ActiveSupport::Concern

  private

  def track_supporting_services_changes_if_any(old_supporting_services)
    new_supporting_services = @establishment_tracking.supporting_services.reload.to_a
    return if old_supporting_services.map(&:id).sort == new_supporting_services.map(&:id).sort

    added = new_supporting_services - old_supporting_services
    removed = old_supporting_services - new_supporting_services
    return if added.empty? && removed.empty?

    description, changes_summary = build_supporting_services_change_data(added, removed)

    @establishment_tracking.snapshot_service.create_event_and_snapshot!(
      event_type: "supporting_services_change",
      triggered_by_user: current_user,
      description: "#{description} for #{@establishment_tracking.establishment.raison_sociale}",
      changes_summary: changes_summary
    )
  end

  def build_supporting_services_change_data(added, removed) # rubocop:disable Metrics/MethodLength
    description_parts = []
    changes_summary = {}

    if added.any?
      description_parts << "Added supporting service(s): #{added.map(&:name).join(', ')}"
      changes_summary[:added] = service_summary(added)
    end

    if removed.any?
      description_parts << "Removed supporting service(s): #{removed.map(&:name).join(', ')}"
      changes_summary[:removed] = service_summary(removed)
    end

    [description_parts.join("; "), changes_summary]
  end

  def service_summary(services)
    services.map { |service| { id: service.id, name: service.name } }
  end
end
