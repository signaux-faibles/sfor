namespace :establishment_tracking do # rubocop:disable Metrics/BlockLength
  desc "Backfill existing establishment trackings with initial snapshots"
  task backfill_snapshots: :environment do # rubocop:disable Metrics/BlockLength
    puts "=== Backfilling EstablishmentTracking Snapshots ===\n"

    # Get all existing trackings - only include basic relationships we actually track
    trackings = EstablishmentTracking.kept.includes(
      :establishment, :creator, :criticality, :size,
      establishment: %i[department region]
    )

    puts "Found #{trackings.count} trackings to backfill"

    progress = 0
    trackings.find_each do |tracking|
      # Set modifier for the snapshot creation
      tracking.modifier = tracking.creator

      # Create initial "creation" event and snapshot using the model method
      tracking.create_event_and_snapshot!(
        event_type: "creation",
        triggered_by_user: tracking.creator,
        description: "Initial snapshot for tracking ##{tracking.id} (backfilled)",
        changes_summary: { backfilled: true, created_at: tracking.created_at }
      )

      # Update the snapshot's created_at to match the original tracking
      snapshot = EstablishmentTrackingSnapshot.where(original_tracking: tracking).order(:created_at).last
      if snapshot
        snapshot.update_column(:created_at, tracking.created_at)
        snapshot.tracking_event.update_column(:created_at, tracking.created_at)
      end

      progress += 1
      puts "✓ Created snapshot for tracking ##{tracking.id} (#{progress}/#{trackings.count})" if (progress % 10).zero?
    rescue StandardError => e
      puts "✗ Error creating snapshot for tracking ##{tracking.id}: #{e.message}"
      puts "  Details: #{e.backtrace.first(3).join('\n  ')}"
    end

    puts "\n=== Backfill Complete ===\n"
    puts "Total snapshots created: #{EstablishmentTrackingSnapshot.count}"
    puts "Total events created: #{TrackingEvent.count}"
  end
end
