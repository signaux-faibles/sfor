# lib/tasks/import_establishments.rake
# Import establishment data from StockEtablissement_utf8.csv (https://files.data.gouv.fr/insee-sirene/)
# usage : rake establishments:import_from_insee file=path/to/your_file.csv

require 'csv'
require 'logger'

namespace :establishments do
  desc "Import establishments from a CSV file"
  task import_from_insee: :environment do
    file_path = ENV['file']

    if file_path.nil?
      puts "Please provide a file path using file=path/to/your_file.csv"
      exit
    end

    log_file = File.open("log/import_establishments.log", "a")
    logger = Logger.new(log_file)

    begin
      establishments_to_insert = []
      companies_to_insert = []
      batch_size = 10_000
      total_inserted = 0

      CSV.foreach(file_path, headers: true, col_sep: ',') do |row|
        begin
          siren = row['siren']
          siret = row['siret']
          code_postal = row['codePostalEtablissement']
          is_siege = row['etablissementSiege'].to_s.downcase == 'true'

          if siren.nil? || siren.strip.empty?
            raise "SIREN absent ou illisible"
          elsif siret.nil? || siret.strip.empty?
            raise "SIRET absent ou illisible"
          elsif code_postal.nil? || code_postal.strip.empty?
            raise "Code postal absent ou illisible"
          end

          # Ignorer les lignes où les deux premiers chiffres du code postal sont "98" ou si le code postal est "[ND]"
          department_code = code_postal[0..1]
          next if department_code == "98" || code_postal == "[ND]"

          # Si les deux premiers chiffres sont "97", utiliser le 3e chiffre pour déterminer le département
          if department_code == "97"
            department_code = case code_postal[2]
                              when "1" then "971" # Guadeloupe
                              when "2" then "972" # Martinique
                              when "3" then "973" # Guyane
                              when "4" then "974" # La Réunion
                              when "6" then "976" # Mayotte
                              else
                                raise "Code postal inconnu pour un département de la région 97 : #{code_postal}"
                              end
          end

          department = Department.find_by(code: department_code)

          if department.nil?
            raise "Département introuvable pour le code postal #{code_postal}"
          end

          establishments_to_insert << {
            siren: siren,
            siret: siret,
            is_siege: is_siege,
            department_id: department.id,
            created_at: Time.now,
            updated_at: Time.now
          }

          if is_siege
            companies_to_insert << {
              siren: siren,
              siret: siret,
              department_id: department.id,
              created_at: Time.now,
              updated_at: Time.now
            }
          end

          # When the buffer reaches the batch size, insert the records in bulk
          if establishments_to_insert.size >= batch_size
            ActiveRecord::Base.transaction do
              Establishment.insert_all(establishments_to_insert)
              Company.insert_all(companies_to_insert)
            end

            total_inserted += establishments_to_insert.size
            puts "Imported #{total_inserted} establishments so far."

            establishments_to_insert.clear
            companies_to_insert.clear
          end

        rescue => e
          logger.error "Erreur lors de l'importation de l'établissement avec SIRET #{row['siret'] || 'Inconnu'}: #{e.message}"
          puts "Erreur lors de l'importation de l'établissement avec SIRET #{row['siret'] || 'Inconnu'}: #{e.message}"
        end
      end

      # Insert any remaining records
      ActiveRecord::Base.transaction do
        Establishment.insert_all(establishments_to_insert) if establishments_to_insert.any?
        Company.insert_all(companies_to_insert) if companies_to_insert.any?
        total_inserted += establishments_to_insert.size
      end

      puts "Imported #{total_inserted} establishments in total."

      puts "Import completed!"
    rescue => e
      logger.fatal "Erreur fatale lors de l'importation : #{e.message}"
      puts "Erreur fatale lors de l'importation : #{e.message}"
    ensure
      log_file.close
    end
  end
end