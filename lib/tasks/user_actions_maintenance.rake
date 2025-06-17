namespace :user_actions do # rubocop:disable Metrics/BlockLength
  desc "Update UserActions: rename, create, keep, reorder, and discard as per new specifications."
  task maintain: :environment do # rubocop:disable Metrics/BlockLength
    renames = {
      "Soutien à la croissance et filière" => "Intermédiation auprès des acteurs de la filière",
      "Prise en charge judiciaire" => "Intermédiation auprès des acteurs administratifs et judiciaires"
    }

    create = [
      "Mobilisation audit CODEFI",
      "Mesures URSSAF de recouvrement forcé",
      "Mise en place d'un délai URSSAF",
      "Aide à la recherche de financement public",
      "Aide à la recherche de financement privé",
      "Restructuration AR-PB",
      "Maintien de l'emploi (Activité Partielle)",
      "Développement des compétences et transitions professionnelles (FNE, Transco, GEPP, etc.)",
      "Appui au recrutement, fidélisation et attractivité",
      "Restructurations sociales (PSE, RCC, etc.)"
    ]

    discard = [
      "Repositionnements et restructurations",
      "Soutien financier public",
      "Médiation avec les partenaires",
      "Échanges avec les créanciers",
      "Appui à une politique d'emploi",
      "Appui à l'installation et gestion immobilière",
      "Coaching, soutien psychologique"
    ]

    final_order = [
      "Mobilisation audit CODEFI",
      "Mesures URSSAF de recouvrement forcé",
      "Mise en place d'un délai URSSAF",
      "Aide à la recherche de financement public",
      "Aide à la recherche de financement privé",
      "Intermédiation auprès des acteurs de la filière",
      "Intermédiation auprès des acteurs administratifs et judiciaires",
      "Restructuration AR-PB",
      "Recherche et suivi de repreneur",
      "Maintien de l'emploi (Activité Partielle)",
      "Développement des compétences et transitions professionnelles (FNE, Transco, GEPP, etc.)",
      "Appui au recrutement, fidélisation et attractivité",
      "Restructurations sociales (PSE, RCC, etc.)"
    ]

    # --- Renames ---
    renames.each do |old, new|
      action = UserAction.with_discarded.find_by(name: old)
      if action
        action.update!(name: new)
        puts "Renamed '#{old}' to '#{new}' and made it active"
      end
    rescue StandardError => e
      puts "[ERROR] Failed to rename action '#{old}' to '#{new}': #{e.message}"
      puts e.backtrace.join("\n")
    end

    # --- Create new actions ---
    create.each do |name|
      action = UserAction.with_discarded.find_or_initialize_by(name: name)
      if action.new_record?
        action.save!
        puts "Created '#{name}'"
      end
    rescue StandardError => e
      puts "[ERROR] Failed to create action '#{name}': #{e.message}"
      puts e.backtrace.join("\n")
    end

    # --- Discard specified actions ---
    discard.each do |name|
      action = UserAction.with_discarded.find_by(name: name)
      if action && !action.discarded?
        action.discard!
        puts "Discarded '#{name}'"
      end
    rescue StandardError => e
      puts "[ERROR] Failed to discard action '#{name}': #{e.message}"
      puts e.backtrace.join("\n")
    end

    # --- Set order (position) for all ---
    final_order.each_with_index do |name, idx|
      action = UserAction.with_discarded.find_by(name: name)
      if action
        action.update!(position: idx)
        action.undiscard! if action.discarded?
        puts "Set position for '#{name}' to #{idx} and made it active"
      else
        puts "[WARNING] Action '#{name}' not found for ordering."
      end
    rescue StandardError => e
      puts "[ERROR] Failed to set position for action '#{name}': #{e.message}"
      puts e.backtrace.join("\n")
    end

    # --- Clear position for discarded actions ---
    begin
      max_position = UserAction.kept.maximum(:position).to_i
      UserAction.discarded.update_all(position: max_position + 1)
      puts "Set position for all discarded actions to #{max_position + 1}."
      puts "Cleared position for all discarded actions."
    rescue StandardError => e
      puts "[ERROR] Failed to clear position for discarded actions: #{e.message}"
      puts e.backtrace.join("\n")
    end

    puts "\nUserActions maintenance complete."
    puts "Current active (kept) actions in order:"
    UserAction.kept.ordered.pluck(:name).each_with_index do |name, idx|
      puts "  #{idx + 1}. #{name}"
    end
    puts "\nDiscarded actions:"
    UserAction.discarded.order(:position).pluck(:name).each do |name|
      puts "  - #{name}"
    end
  end
end
