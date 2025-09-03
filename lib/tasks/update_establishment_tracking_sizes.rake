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

    # Fonction pour analyser les changements
    def analyze_changes(company, new_size, stats)
      return unless new_size

      company.establishments.includes(:establishment_trackings).find_each do |establishment|
        establishment.establishment_trackings.each do |tracking|
          current_size_name = tracking.size&.name || "nil"
          new_size_name = new_size.name

          if current_size_name != "nil"
            if current_size_name == new_size_name
              stats[:changes_analysis][current_size_name]["unchanged"] += 1
            else
              stats[:changes_analysis][current_size_name][new_size_name] += 1
            end
          end
        end
      end
    end

    # Fonction pour afficher le rapport des changements
    def display_changes_report(stats)
      puts "📊 ANALYSE DES CHANGEMENTS PRÉVUS"
      puts "=" * 50

      stats[:changes_analysis].each do |current_size, changes|
        total_current = changes.values.sum
        next if total_current.zero?

        puts "\n📈 Among #{total_current} establishment_trackings with size \"#{current_size}\":"
        changes.each do |new_size, count|
          next if count.zero?

          if new_size == "unchanged"
            puts "  • #{count} will remain #{current_size}"
          else
            puts "  • #{count} will become #{new_size}"
          end
        end
      end
      puts
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

    companies.each_with_index do |company, index| # rubocop:disable Metrics/BlockLength
      puts "🔍 [#{index + 1}/#{total_companies}] Traitement de #{company.siren} - #{company.raison_sociale}"

      begin
        puts "  🌐 Appel API INSEE..."
        api_response = service.fetch_unite_legale_by_siren(company.siren)
        puts "  ✅ Réponse API reçue"

        if api_response&.dig("data", "tranche_effectif_salarie")
          effectif_data = api_response.dig("data", "tranche_effectif_salarie")
          effectif_min = effectif_data["de"]
          effectif_max = effectif_data["a"]

          # Déterminer la taille
          size = determine_size(effectif_min, effectif_max, sizes)

          if size
            # Analyser les changements prévus
            analyze_changes(company, size, stats)

            # Récupérer tous les establishment_trackings via les establishments
            establishment_trackings = company.establishments.includes(:establishment_trackings).map(&:establishment_trackings).flatten # rubocop:disable Layout/LineLength

            if establishment_trackings.any?
              stats[:updated_trackings] += establishment_trackings.count
              stats[:size_distribution][size.name] += establishment_trackings.count
              puts "  ✅ #{establishment_trackings.count} tracking(s) → #{size.name} (#{effectif_min}-#{effectif_max} salariés)"
            else
              puts "  ℹ️  Aucun establishment_tracking trouvé"
            end
          else
            puts "  ⚠️  Impossible de déterminer la taille (effectif: #{effectif_min}-#{effectif_max})"
            stats[:missing_data] << {
              siren: company.siren,
              raison_sociale: company.raison_sociale,
              reason: "Effectif hors plage: #{effectif_min}-#{effectif_max}"
            }
          end
        else
          puts "  ❌ Pas de données d'effectif dans la réponse API"
          stats[:missing_data] << {
            siren: company.siren,
            raison_sociale: company.raison_sociale,
            reason: "Pas de tranche_effectif_salarie dans l'API"
          }
        end
      rescue StandardError => e
        puts "  💥 Erreur API - #{e.message}"
        stats[:api_errors] += 1
        stats[:missing_data] << {
          siren: company.siren,
          raison_sociale: company.raison_sociale,
          reason: "Erreur API: #{e.message}"
        }
      end

      # Pause pour respecter les limites de l'API et éviter le blocage
      sleep(1)
    end

    # Afficher le rapport des changements prévus
    display_changes_report(stats)

    # Demander confirmation avant de procéder
    puts "🤔 Voulez-vous procéder à la mise à jour ? (tapez 'yes' pour confirmer)"
    confirmation = $stdin.gets.chomp.downcase

    unless confirmation == "yes"
      puts "❌ Mise à jour annulée par l'utilisateur"
      exit 0
    end

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
            establishment_trackings = company.establishments.includes(:establishment_trackings).map(&:establishment_trackings).flatten

            if establishment_trackings.any?
              puts "  🔍 #{establishment_trackings.count} establishment_tracking(s) trouvé(s)"

              updated_count = 0
              establishment_trackings.each_with_index do |tracking, tracking_index|
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
              puts "  ℹ️  Aucun establishment_tracking trouvé"
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
