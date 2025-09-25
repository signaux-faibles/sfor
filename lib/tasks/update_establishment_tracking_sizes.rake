# lib/tasks/update_establishment_tracking_sizes.rake
# Rake task to update establishment_tracking sizes based on INSEE API data
# Usage: rake companies:update_sizes
# rubocop:disable all

namespace :companies do # rubocop:disable Metrics/BlockLength
  desc "Update establishment_tracking sizes based on INSEE API effectif data"
  task update_sizes: :environment do # rubocop:disable Metrics/BlockLength
    puts "🚀 Démarrage de la mise à jour des tailles d'entreprise depuis l'API INSEE"
    puts "=" * 80

    # Statistiques
    stats = {
      total_companies: 0,
      updated_trackings: 0,
      api_errors: 0,
      missing_data: [],
      size_distribution: { "TPE" => 0, "PME" => 0, "ETI" => 0, "GE" => 0 },
      changes_analysis: {
        "nil" => { "TPE" => 0, "PME" => 0, "ETI" => 0, "GE" => 0 },
        "TPE" => { "PME" => 0, "ETI" => 0, "GE" => 0, "unchanged" => 0 },
        "PME" => { "TPE" => 0, "ETI" => 0, "GE" => 0, "unchanged" => 0 },
        "ETI" => { "TPE" => 0, "PME" => 0, "GE" => 0, "unchanged" => 0 },
        "GE" => { "TPE" => 0, "PME" => 0, "ETI" => 0, "unchanged" => 0 }
      }
    }

    # Récupérer tous les sizes pour le mapping
    sizes = {
      "TPE" => Size.find_by(name: "TPE"),
      "PME" => Size.find_by(name: "PME"),
      "ETI" => Size.find_by(name: "ETI"),
      "GE" => Size.find_by(name: "GE")
    }

    # Récupérer le segment CRP
    crp_segment = Segment.find_by(name: "crp")
    unless crp_segment
      puts "❌ Segment 'CRP' not found. Please check your database."
      exit 1
    end

    # Date de filtrage
    filter_date = Date.new(2025, 1, 1)

    # Initialiser la répartition par taille d'accompagnements (distribution globale après mise à jour)
    tracking_size_distribution = { "TPE" => 0, "PME" => 0, "ETI" => 0, "GE" => 0 }
    
    # Compter d'abord tous les trackings existants (pour la répartition de base)
    all_trackings_count = EstablishmentTracking.where(discarded_at: nil).count
    existing_distribution = EstablishmentTracking
      .joins(:size)
      .where(discarded_at: nil)
      .group('sizes.name')
      .count

    # Vérifier que tous les sizes existent
    missing_sizes = sizes.select { |_, size| size.nil? }.keys
    if missing_sizes.any?
      puts "⚠️  Attention: Les tailles suivantes n'existent pas en base: #{missing_sizes.join(', ')}"
      puts "   Seules les tailles existantes seront utilisées."
    end

    puts "✅ Sizes disponibles: #{sizes.compact.keys.join(', ')}"
    puts

    # Fonction pour déterminer la taille selon l'effectif
    def determine_size(effectif_min, effectif_max, sizes) # rubocop:disable Metrics/MethodLength,Rake/MethodDefinitionInTask
      # Utiliser la valeur maximale pour déterminer la catégorie
      effectif = effectif_max || effectif_min || 0

      case effectif
      when 0..10
        sizes["TPE"]
      when 11..250
        sizes["PME"]
      when 251..4999
        sizes["ETI"]
      when 5000..Float::INFINITY
        sizes["GE"]
      end
    end

    # Traitement simple sans batch
    puts "🔄 Récupération des entreprises..."
    companies = Company.all
    puts "✅ Requête exécutée"
    total_companies = companies.size
    stats[:total_companies] = total_companies

    puts "📊 #{total_companies} entreprises à traiter"
    puts "🔄 Début du traitement..."
    puts

    # Créer le service API une seule fois pour optimiser les performances
    puts "🔧 Initialisation du service API INSEE..."
    service = Api::InseeApiService.new
    puts "✅ Service API initialisé"
    puts

    puts "\n🚀 Début de la mise à jour effective..."
    puts "=" * 50

    # Phase 2: Application effective des changements
    companies.each_with_index do |company, index|
      puts "🔄 [#{index + 1}/#{total_companies}] Mise à jour de #{company.siren} - #{company.raison_sociale}"

      begin
        puts "  🌐 Appel API INSEE..."
        api_response = service.fetch_unite_legale_by_siren(company.siren)
        puts "  ✅ Réponse API reçue"

        if api_response&.dig("data", "tranche_effectif_salarie")
          effectif_data = api_response.dig("data", "tranche_effectif_salarie")
          effectif_min = effectif_data["de"]
          effectif_max = effectif_data["a"]
          puts "  📊 Effectif: #{effectif_min}-#{effectif_max} salariés"

          size = determine_size(effectif_min, effectif_max, sizes)

          if size
            puts "  🎯 Nouvelle taille déterminée: #{size.name}"
            # Récupérer les trackings filtrés (TPE uniquement)
            filtered_trackings = company.establishments
              .joins(:establishment_trackings)
              .joins(establishment_trackings: :size)
              .where(establishment_trackings: { discarded_at: nil })
              .distinct
              .pluck("establishment_trackings.id")

            if filtered_trackings.any?
              puts "  🔍 #{filtered_trackings.count} establishment_tracking(s) filtré(s) trouvé(s)"

              updated_count = 0
              filtered_trackings.each_with_index do |tracking_id, tracking_index|
                tracking = EstablishmentTracking.find(tracking_id)
                old_size_name = tracking.size&.name || "nil"
                tracking.update!(size_id: size.id)
                updated_count += 1

                if old_size_name == size.name
                  puts "    📝 Tracking #{tracking_index + 1}: #{old_size_name} (inchangé)"
                else
                  puts "    📝 Tracking #{tracking_index + 1}: #{old_size_name} → #{size.name}"
                end
              end
              puts "  ✅ #{updated_count} tracking(s) traité(s) → #{size.name}"
            else
              puts "  ℹ️  Aucun establishment_tracking filtré trouvé"
            end
          else
            puts "  ⚠️  Impossible de déterminer la taille (effectif: #{effectif_min}-#{effectif_max})"
          end
        else
          puts "  ❌ Pas de données d'effectif dans la réponse API"
        end
      rescue StandardError => e
        puts "  💥 Erreur API: #{e.message}"
      end

      puts "  ⏱️  Pause de 3 secondes..."
      sleep(3)
      puts
    end

    # Affichage des résultats finaux
    puts "=" * 80
    puts "📊 RÉSULTATS FINAUX"
    puts "=" * 80
    puts "🏢 Entreprises traitées: #{stats[:total_companies]}"
    puts "✅ Trackings mis à jour: #{stats[:updated_trackings]}"
    puts "❌ Erreurs API: #{stats[:api_errors]}"
    puts "⚠️  Données manquantes: #{stats[:missing_data].size}"
    puts

    puts "📊 RÉPARTITION PAR TAILLE:"
    stats[:size_distribution].each do |size_name, count|
      percentage = (stats[:updated_trackings]).positive? ? (count * 100.0 / stats[:updated_trackings]).round(1) : 0
      puts "  #{size_name}: #{count} trackings (#{percentage}%)"
    end
    puts

    # Afficher les SIREN problématiques
    if stats[:missing_data].any?
      puts "⚠️  ENTREPRISES SANS DONNÉES D'EFFECTIF:"
      puts "=" * 50
      stats[:missing_data].each do |item|
        puts "  🔸 #{item[:siren]} - #{item[:raison_sociale]} (#{item[:reason]})"
      end
      puts
      puts "📋 LISTE DES SIREN POUR INVESTIGATION:"
      siren_list = stats[:missing_data].map { |item| item[:siren] }.join(", ")
      puts siren_list
    end

    puts "🎉 Tâche terminée avec succès!"
  end
end
