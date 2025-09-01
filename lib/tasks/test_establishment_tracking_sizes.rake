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
      missing_data: []
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

    # Traitement d'un échantillon
    companies = Company.includes(establishments: :establishment_trackings).limit(limit)

    companies.each_with_index do |company, index| # rubocop:disable Metrics/BlockLength
      puts "🔍 [#{index + 1}/#{limit}] Test pour #{company.siren} - #{company.raison_sociale}"

      begin
        service = Api::InseeApiService.new(siren: company.siren)
        api_response = service.fetch_unite_legale

        if api_response&.dig("data", "tranche_effectif_salarie")
          effectif_data = api_response.dig("data", "tranche_effectif_salarie")
          effectif_min = effectif_data["de"]
          effectif_max = effectif_data["a"]

          size = determine_size_test(effectif_min, effectif_max, sizes)

          if size
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
      sleep(3)
      puts
    end

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
