namespace :establishment_trackings do
  desc "Add 'Pas de criticité' to EstablishmentTrackings without a criticality"
  task add_default_criticality: :environment do
    # Find or create the "Pas de criticité" criticality
    default_criticality = Criticality.find_or_create_by!(name: "Pas de criticité")

    # Find all EstablishmentTrackings without a criticality
    trackings_without_criticality = EstablishmentTracking.where(criticality_id: nil)

    # Update them with the default criticality
    count = trackings_without_criticality.update_all(criticality_id: default_criticality.id)

    puts "Updated #{count} EstablishmentTrackings with 'Pas de criticité'"
  end
end
