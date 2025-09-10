# lib/tasks/test_establishment_tracking_sizes.rake
# Test version of the size update task - processes only a small sample
# Usage: rake companies:test_update_sizes[10]
# rubocop:disable all

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
        "nil" => { "TPE" => 0, "PME" => 0, "ETI" => 0, "GE" => 0 },
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

    # Récupérer le segment CRP
    crp_segment = Segment.find_by(name: "crp")
    unless crp_segment
      puts "❌ Segment 'crp' not found. Please check your database."
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
    def analyze_changes_test(company, new_size, stats, crp_segment, filter_date, tracking_size_distribution, existing_distribution)
      return unless new_size

      # Récupérer les trackings filtrés (TPE uniquement)
      filtered_trackings = company.establishments
        .joins(:establishment_trackings)
        .joins(establishment_trackings: :size)
        .where(establishment_trackings: { discarded_at: nil })
        .where("establishment_trackings.modified_at >= ?", filter_date)
        .where(sizes: { name: "TPE" })
        .where(
          "establishment_trackings.id IN (
            SELECT et.id FROM establishment_trackings et
            INNER JOIN tracking_referents tr ON tr.establishment_tracking_id = et.id
            INNER JOIN users u ON u.id = tr.user_id
            WHERE u.segment_id = ?
          )",
          crp_segment.id
        )
        .distinct
        .pluck("establishment_trackings.id")

      # Mettre à jour le compteur total des trackings traités
      stats[:updated_trackings] += filtered_trackings.count

      # Analyser chaque tracking filtré
      filtered_trackings.each do |tracking_id|
        tracking = EstablishmentTracking.find(tracking_id)
        current_size_name = tracking.size&.name || "nil"
        new_size_name = new_size.name

        if current_size_name == "nil"
          # Tracking sans taille actuelle
          stats[:changes_analysis]["nil"][new_size_name] += 1
        else
          # Tracking avec taille existante
          if current_size_name == new_size_name
            stats[:changes_analysis][current_size_name]["unchanged"] += 1
          else
            stats[:changes_analysis][current_size_name][new_size_name] += 1
          end
        end
      end
    end

    # Fonction pour calculer la nouvelle répartition globale (version test)
    def calculate_new_distribution_test(existing_distribution, stats)
      new_distribution = existing_distribution.dup
      
      # Appliquer les changements
      stats[:changes_analysis].each do |current_size, changes|
        changes.each do |new_size, count|
          next if count.zero? || new_size == "unchanged"
          
          # Retirer de l'ancienne taille
          if current_size != "nil"
            new_distribution[current_size] = (new_distribution[current_size] || 0) - count
          end
          
          # Ajouter à la nouvelle taille
          new_distribution[new_size] = (new_distribution[new_size] || 0) + count
        end
      end
      
      # S'assurer que toutes les tailles sont présentes
      { "TPE" => 0, "PME" => 0, "ETI" => 0, "GE" => 0 }.each do |size_name, _|
        new_distribution[size_name] ||= 0
      end
      
      new_distribution
    end

    # Fonction pour afficher le rapport des changements (version test)
    def display_changes_report_test(stats, new_distribution, existing_distribution)
      puts "\n📊 ANALYSE DES CHANGEMENTS PRÉVUS (TEST)"
      puts "=" * 50

      # Afficher la répartition actuelle
      puts "\n📊 RÉPARTITION ACTUELLE"
      puts "-" * 30
      total_current = existing_distribution.values.sum
      existing_distribution.each do |size_name, count|
        percentage = total_current > 0 ? (count.to_f / total_current * 100).round(1) : 0
        puts "  • #{size_name}: #{count} accompagnements (#{percentage}%)"
      end
      puts "  • Total: #{total_current} accompagnements"

      # Afficher la nouvelle répartition après mise à jour
      puts "\n📋 NOUVELLE RÉPARTITION APRÈS MISE À JOUR DES TRACKINGS TPE"
      puts "-" * 60
      total_new = new_distribution.values.sum
      new_distribution.each do |size_name, count|
        percentage = total_new > 0 ? (count.to_f / total_new * 100).round(1) : 0
        puts "  • #{size_name}: #{count} accompagnements (#{percentage}%)"
      end
      puts "  • Total: #{total_new} accompagnements"

      # Afficher les changements par taille actuelle
      puts "\n📈 CHANGEMENTS PAR TAILLE ACTUELLE"
      puts "-" * 40
      stats[:changes_analysis].each do |current_size, changes|
        total_current = changes.values.sum
        next if total_current.zero?

        size_label = current_size == "nil" ? "no size" : "\"#{current_size}\""
        puts "\n📈 Among #{total_current} establishment_trackings with #{size_label}:"
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
            analyze_changes_test(company, size, stats, crp_segment, filter_date, tracking_size_distribution, existing_distribution)

            # Compter les establishment_trackings filtrés (TPE uniquement)
            filtered_trackings = company.establishments
              .joins(:establishment_trackings)
              .joins(establishment_trackings: :size)
              .where(establishment_trackings: { discarded_at: nil })
              .where("establishment_trackings.modified_at >= ?", filter_date)
              .where(sizes: { name: "TPE" })
              .where(
                "establishment_trackings.id IN (
                  SELECT et.id FROM establishment_trackings et
                  INNER JOIN tracking_referents tr ON tr.establishment_tracking_id = et.id
                  INNER JOIN users u ON u.id = tr.user_id
                  WHERE u.segment_id = ?
                )",
                crp_segment.id
              )
              .distinct
              .count

            puts "  ✅ Recommandation: #{size.name} (#{effectif_min}-#{effectif_max} salariés)"
            puts "     → Affecterait #{filtered_trackings} establishment_tracking(s) filtré(s)"

            # En mode test, on ne fait PAS la mise à jour
            # (stats[:updated_trackings] est déjà mis à jour dans analyze_changes_test)
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
      sleep(0.1)
      puts
    end

    # Calculer la nouvelle répartition globale
    new_distribution = calculate_new_distribution_test(existing_distribution, stats)
    
    # Afficher le rapport des changements prévus
    display_changes_report_test(stats, new_distribution, existing_distribution)

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
