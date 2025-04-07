# lib/tasks/establishment_tracking_contacts.rake
# Create contact instances for establishments based on the value of the contact attribute of the establishment_trackings
# usage : rake establishment_tracking:create_contacts_from_trackings

namespace :establishment_tracking do
  desc "Créer des contacts pour les accompagnements avec un champ 'contact' non vide"
  task create_contacts_from_trackings: :environment do
    EstablishmentTracking.find_each do |tracking|
      next if tracking.contact.blank?

      tracking.establishment.contacts.create!(
        description: tracking.contact,
        first_name: "Prénom",
        last_name: "Nom"
      )
      puts "Contact créé pour l'établissement d'id : ##{tracking.establishment_id}"
    rescue StandardError => e
      Rails.logger.error "Erreur lors du traitement de tracking ##{tracking.id}: #{e.message}"
    end

    puts "Tâche terminée : les contacts ont été créés."
  end
end
