# lib/tasks/force_trackings_modified_at.rake
# Force the update of the modified_at attribute for EstablishmentTrackings if a more recent summary or comment is found
# usage : rake trackings:update_modified_at

namespace :trackings do
  desc "Analyse et met à jour la date de dernière modification de tous les accompagnements"
  task update_modified_at: :environment do
    puts "Mise à jour des dates de modifications des accompagnements..."

    EstablishmentTracking.find_each do |tracking|
      last_modification_date = tracking.modified_at
      last_comment_date = tracking.comments.maximum(:created_at)
      last_summary_date = tracking.summaries.maximum(:updated_at)

      most_recent_date = [last_modification_date, last_comment_date, last_summary_date].compact.max

      if most_recent_date && most_recent_date > last_modification_date
        tracking.update(modified_at: most_recent_date)
        puts "Mise à jour pour l'accompagnement #{tracking.id} : Nouvelle date #{most_recent_date}"
      else
        puts "Aucune mise à jour nécessaire pour l'accompagnement #{tracking.id}."
      end
    end

    puts "Mise à jour terminée !"
  end
end
