# lib/tasks/update_establishment_tracking_sizes.rake
# Rake task to update establishment_tracking sizes based on INSEE API data
# Usage: rake companies:update_sizes

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
      size_distribution: { "TPE" => 0, "PME" => 0, "ETI" => 0, "GE" => 0 }
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

    # Traitement simple sans batch
    puts "🔄 Récupération des entreprises..."
    companies = Company.all
    puts "✅ Requête exécutée"
    total_companies = companies.size
    stats[:total_companies] = total_companies

    puts "📊 #{total_companies} entreprises à traiter"
    puts "🔄 Début du traitement..."
    puts

    companies.each_with_index do |company, index| # rubocop:disable Metrics/BlockLength
      puts "🔍 [#{index + 1}/#{total_companies}] Traitement de #{company.siren} - #{company.raison_sociale}"

      begin
        puts "  🔄 Création du service API..."
        service = Api::InseeApiService.new(siren: company.siren)
        puts "  🌐 Appel API INSEE..."
        api_response = service.fetch_unite_legale
        puts "  ✅ Réponse API reçue"

        if api_response&.dig("data", "tranche_effectif_salarie")
          effectif_data = api_response.dig("data", "tranche_effectif_salarie")
          effectif_min = effectif_data["de"]
          effectif_max = effectif_data["a"]

          # Déterminer la taille
          size = determine_size(effectif_min, effectif_max, sizes)

          if size
            # Récupérer tous les establishment_trackings via les establishments
            establishment_trackings = company.establishments.includes(:establishment_trackings).map(&:establishment_trackings).flatten # rubocop:disable Layout/LineLength

            if establishment_trackings.any?
              # Mettre à jour tous les establishment_trackings
              updated_count = 0
              establishment_trackings.each do |tracking|
                tracking.update!(size_id: size.id)
                updated_count += 1
              end

              stats[:updated_trackings] += updated_count
              stats[:size_distribution][size.name] += updated_count
              puts "  ✅ #{updated_count} tracking(s) → #{size.name} (#{effectif_min}-#{effectif_max} salariés)"
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
      sleep(3)
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
