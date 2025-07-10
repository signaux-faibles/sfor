class EstablishmentTrackingSnapshotService
  def initialize(establishment_tracking)
    @tracking = establishment_tracking
  end

  def create_snapshot!(event)
    EstablishmentTrackingSnapshot.create!(snapshot_attributes(event))
  end

  def create_event_and_snapshot!(event_type:, triggered_by_user:, description: nil, changes_summary: {})
    TrackingEvent.create_event!(
      establishment_tracking: @tracking,
      event_type: event_type,
      triggered_by_user: triggered_by_user,
      description: description,
      changes_summary: changes_summary
    )
    # NOTE: TrackingEvent.create_event! automatically creates the snapshot
  end

  private

  def snapshot_attributes(event) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    {
      original_tracking: @tracking,
      tracking_event: event,
      creator_email: @tracking.creator.email,
      state: @tracking.state,
      start_date: @tracking.start_date,
      end_date: @tracking.end_date,
      criticality_name: @tracking.criticality&.name,
      label_names: @tracking.tracking_labels.pluck(:name),
      supporting_service_names: @tracking.supporting_services.pluck(:name),
      difficulty_names: @tracking.difficulties.pluck(:name),
      user_action_names: @tracking.user_actions.pluck(:name),
      codefi_redirect_names: @tracking.codefi_redirects.pluck(:name),
      sector_names: @tracking.sectors.pluck(:name),
      size_name: @tracking.size&.name,
      establishment_siret: @tracking.establishment.siret,
      establishment_department_code: @tracking.establishment.department&.code,
      establishment_department_name: @tracking.establishment.department&.name,
      establishment_region_code: @tracking.establishment.department&.region&.code,
      establishment_region_name: @tracking.establishment.department&.region&.libelle
    }.merge(user_snapshot_attributes)
  end

  def user_snapshot_attributes # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    {
      referent_emails: @tracking.referents.kept.pluck(:email),
      participant_emails: @tracking.participants.kept.pluck(:email),
      referent_segment_names: @tracking.referents.kept.includes(:segment).filter_map { |u| u.segment&.name },
      participant_segment_names: @tracking.participants.kept.includes(:segment).filter_map { |u| u.segment&.name },
      referent_entity_names: @tracking.referents.kept.includes(:entity).filter_map { |u| u.entity&.name },
      participant_entity_names: @tracking.participants.kept.includes(:entity).filter_map { |u| u.entity&.name }
    }
  end
end
