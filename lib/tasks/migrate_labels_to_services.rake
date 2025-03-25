namespace :migrate do
  desc 'Migrate specific tracking labels to supporting services'
  task labels_to_services: :environment do
    label_to_service_mapping = {
      'CODEFI' => 'CODEFI',
      'CIRI' => 'CIRI',
      'MRE' => 'MRE',
      'DIRE' => 'DIRE'
    }

    services = {}
    label_to_service_mapping.each do |_, service_name|
      services[service_name] = SupportingService.find_or_create_by!(name: service_name)
    end

    EstablishmentTracking.find_each do |tracking|
      labels_to_migrate = tracking.tracking_labels.where(name: label_to_service_mapping.keys)
      
      if labels_to_migrate.any?
        puts "Processing tracking #{tracking.id} for establishment #{tracking.establishment.siret}"
        
        labels_to_migrate.each do |label|
          service_name = label_to_service_mapping[label.name]
          tracking.supporting_services << services[service_name] unless tracking.supporting_services.include?(services[service_name])
          puts "  Added service: #{service_name}"
        end
        
        tracking.tracking_labels.delete(labels_to_migrate)
        puts "  Removed labels: #{labels_to_migrate.pluck(:name).join(', ')}"
      end
    end

    puts "Migration completed!"
  end
end 