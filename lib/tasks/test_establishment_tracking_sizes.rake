# lib/tasks/test_establishment_tracking_sizes.rake
# Test version of the size update task - processes only a small sample
# Usage: rake companies:test_update_sizes[10]

namespace :companies do # rubocop:disable Metrics/BlockLength
  desc "Test update of establishment_tracking sizes (limited sample)"
  task :test_update_sizes, [:limit] => :environment do |_task, args| # rubocop:disable Metrics/BlockLength
    limit = (args[:limit] || 5).to_i

    puts "🧪 TEST - Mise à jour des tailles d'entreprise (#{limit} entreprises)"
    puts "=" * 60

    # Statistiques de test
    stats = {
      processed: 0,
      updated_trackings: 0,
      api_errors: 0,
      missing_data: [],
      changes_analysis: {
        "TPE" => { "PME" => 0, "ETI" => 0, "GE" => 0, "unchanged" => 0 },
        "PME" => { "TPE" => 0, "ETI" => 0, "GE" => 0, "unchanged" => 0 },
        "ETI" => { "TPE" => 0, "PME" => 0, "GE" => 0, "unchanged" => 0 },
        "GE" => { "TPE" => 0, "PME" => 0, "ETI" => 0, "unchanged" => 0 }
      }
    }

    # Récupérer les sizes
    sizes = {
      "TPE" => Size.find_by(name: "TPE"),
      "PME" => Size.find_by(name: "PME"),
      "ETI" => Size.find_by(name: "ETI"),
      "GE" => Size.find_by(name: "GE")
    }

    # Fonction pour déterminer la taille
    def determine_size_test(effectif_min, effectif_max, sizes) # rubocop:disable Rake/MethodDefinitionInTask
      effectif = effectif_max || effectif_min || 0
      case effectif
      when 0..10 then sizes["TPE"]
      when 11..250 then sizes["PME"]
      when 251..4999 then sizes["ETI"]
      when 5000..Float::INFINITY then sizes["GE"]
      end
    end

    # Fonction pour analyser les changements (version test)
    def analyze_changes_test(company, new_size, stats)
      return unless new_size

      company.establishments.includes(:establishment_trackings).each do |establishment|
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

    # Fonction pour afficher le rapport des changements (version test)
    def display_changes_report_test(stats)
      puts "\n📊 ANALYSE DES CHANGEMENTS PRÉVUS (TEST)"
      puts "=" * 50

      stats[:changes_analysis].each do |current_size, changes|
        total_current = changes.values.sum
        next if total_current == 0

        puts "\n📈 Among #{total_current} establishment_trackings with size \"#{current_size}\":"
        changes.each do |new_size, count|
          next if count == 0

          if new_size == "unchanged"
            puts "  • #{count} will remain #{current_size}"
          else
            puts "  • #{count} will become #{new_size}"
          end
        end
      end
      puts
    end

    # Traitement d'un échantillon
    companies = Company.includes(establishments: :establishment_trackings).limit(limit)

    # Créer le service API une seule fois pour optimiser les performances
    puts "🔧 Initialisation du service API INSEE..."
    service = Api::InseeApiService.new
    puts "✅ Service API initialisé"
    puts

    companies.each_with_index do |company, index| # rubocop:disable Metrics/BlockLength
      puts "🔍 [#{index + 1}/#{limit}] Test pour #{company.siren} - #{company.raison_sociale}"

      begin
        api_response = service.fetch_unite_legale_by_siren(company.siren)

        if api_response&.dig("data", "tranche_effectif_salarie")
          effectif_data = api_response.dig("data", "tranche_effectif_salarie")
          effectif_min = effectif_data["de"]
          effectif_max = effectif_data["a"]

          size = determine_size_test(effectif_min, effectif_max, sizes)

          if size
            # Analyser les changements prévus
            analyze_changes_test(company, size, stats)

            # Compter les establishment_trackings via les establishments
            tracking_count = company.establishments.map(&:establishment_trackings).flatten.count
            puts "  ✅ Recommandation: #{size.name} (#{effectif_min}-#{effectif_max} salariés)"
            puts "     → Affecterait #{tracking_count} establishment_tracking(s)"

            # En mode test, on ne fait PAS la mise à jour
            stats[:updated_trackings] += tracking_count
          else
            puts "  ❌ Impossible de déterminer la taille"
            stats[:missing_data] << company.siren
          end
        else
          puts "  ⚠️  Pas de données d'effectif"
          stats[:missing_data] << company.siren
        end

        stats[:processed] += 1
      rescue StandardError => e
        puts "  💥 Erreur: #{e.message}"
        stats[:api_errors] += 1
        stats[:missing_data] << company.siren
      end

      # Pause pour éviter le blocage de l'API
      sleep(1)
      puts
    end

    # Afficher le rapport des changements prévus
    display_changes_report_test(stats)

    # Résumé du test
    puts "=" * 60
    puts "📊 RÉSUMÉ DU TEST"
    puts "=" * 60
    puts "🏢 Entreprises testées: #{stats[:processed]}"
    puts "✅ Trackings qui seraient mis à jour: #{stats[:updated_trackings]}"
    puts "❌ Erreurs: #{stats[:api_errors]}"
    puts "⚠️  Sans données: #{stats[:missing_data].size}"

    if stats[:missing_data].any?
      puts
      puts "🔸 SIREN problématiques: #{stats[:missing_data].join(', ')}"
    end

    puts
    puts "💡 Pour lancer la mise à jour complète: rake companies:update_sizes"
  end
end
