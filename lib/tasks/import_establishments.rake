# lib/tasks/import_establishments.rake
# Import establishment data from StockEtablissement_utf8.csv (https://files.data.gouv.fr/insee-sirene/)
# usage : rake establishments:import_from_insee file=path/to/your_file.csv

require "csv"
require "logger"

class ImportEstablishmentsService # rubocop:disable Metrics/ClassLength
  def initialize(file_path)
    @file_path = file_path
    @log_file = File.open("log/import_establishments.log", "a")
    @logger = Logger.new(@log_file)
    @establishments_to_insert = []
    @companies_to_insert = []
    @batch_size = 10_000
    @total_inserted = 0
  end

  def perform
    process_csv
    insert_remaining_records
    puts "Imported #{@total_inserted} establishments in total."
    puts "Import completed!"
  rescue StandardError => e
    @logger.fatal "Erreur fatale lors de l'importation : #{e.message}"
    puts "Erreur fatale lors de l'importation : #{e.message}"
  ensure
    @log_file.close
  end

  private

  def process_csv
    CSV.foreach(@file_path, headers: true, col_sep: ",") do |row|
      process_row(row)
    end
  end

  def process_row(row)
    validate_row(row)
    department = find_department(row["codePostalEtablissement"])
    add_to_buffers(row, department)
    insert_if_batch_full
  rescue StandardError => e
    log_error(row, e)
  end

  def validate_row(row)
    siren = row["siren"]
    siret = row["siret"]
    code_postal = row["codePostalEtablissement"]

    raise "SIREN absent ou illisible" if siren.nil? || siren.strip.empty?
    raise "SIRET absent ou illisible" if siret.nil? || siret.strip.empty?
    raise "Code postal absent ou illisible" if code_postal.nil? || code_postal.strip.empty?
  end

  def find_department(code_postal)
    department_code = extract_department_code(code_postal)
    department = Department.find_by(code: department_code)
    raise "Département introuvable pour le code postal #{code_postal}" if department.nil?

    department
  end

  def extract_department_code(code_postal)
    return nil if code_postal == "[ND]"

    department_code = code_postal[0..1]
    return nil if department_code == "98"
    return extract_overseas_department(code_postal) if department_code == "97"

    department_code
  end

  def extract_overseas_department(code_postal)
    case code_postal[2]
    when "1" then "971"
    when "2" then "972"
    when "3" then "973"
    when "4" then "974"
    when "6" then "976"
    else
      raise "Code postal inconnu pour un département de la région 97 : #{code_postal}"
    end
  end

  def add_to_buffers(row, department)
    is_siege = row["etablissementSiege"].to_s.downcase == "true"
    timestamp = Time.now

    @establishments_to_insert << create_establishment_record(row, department, timestamp)
    @companies_to_insert << create_company_record(row, department, timestamp) if is_siege
  end

  def create_establishment_record(row, department, timestamp)
    {
      siren: row["siren"],
      siret: row["siret"],
      is_siege: row["etablissementSiege"].to_s.downcase == "true",
      department_id: department.id,
      created_at: timestamp,
      updated_at: timestamp
    }
  end

  def create_company_record(row, department, timestamp)
    {
      siren: row["siren"],
      siret: row["siret"],
      department_id: department.id,
      created_at: timestamp,
      updated_at: timestamp
    }
  end

  def insert_if_batch_full
    return unless @establishments_to_insert.size >= @batch_size

    ActiveRecord::Base.transaction do
      Establishment.insert_all(@establishments_to_insert)
      Company.insert_all(@companies_to_insert)
    end

    @total_inserted += @establishments_to_insert.size
    puts "Imported #{@total_inserted} establishments so far."

    @establishments_to_insert.clear
    @companies_to_insert.clear
  end

  def insert_remaining_records
    ActiveRecord::Base.transaction do
      Establishment.insert_all(@establishments_to_insert) if @establishments_to_insert.any?
      Company.insert_all(@companies_to_insert) if @companies_to_insert.any?
      @total_inserted += @establishments_to_insert.size
    end
  end

  def log_error(row, error)
    error_message = "Erreur lors de l'importation de l'établissement avec SIRET " \
                    "#{row['siret'] || 'Inconnu'}: #{error.message}"
    @logger.error error_message
    puts error_message
  end
end

namespace :establishments do
  desc "Import establishments from a CSV file"
  task import_from_insee: :environment do
    file_path = ENV.fetch("file", nil)

    if file_path.nil?
      puts "Please provide a file path using file=path/to/your_file.csv"
      exit
    end

    service = ImportEstablishmentsService.new(file_path)
    service.perform
  end
end
