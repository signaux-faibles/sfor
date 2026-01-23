# app/services/excel/list_generator.rb
module Excel
  module Styles
    def header_style(sheet)
      sheet.styles.add_style(
        b: true,
        alignment: { horizontal: :center, vertical: :center },
        sz: 12,
        bg_color: "CCCCCC",
        border: { style: :thick, color: "000000" }
      )
    end

    def centered_style(sheet)
      sheet.styles.add_style(
        alignment: { horizontal: :center, vertical: :center },
        border: { style: :thin, color: "000000" }
      )
    end

    def summary_style(sheet)
      sheet.styles.add_style(
        alignment: { horizontal: :left, vertical: :center, wrap_text: true },
        border: { style: :thin, color: "000000" }
      )
    end

    def wrap_text_style(sheet)
      sheet.styles.add_style(
        alignment: { wrap_text: true, horizontal: :center, vertical: :center },
        border: { style: :thin, color: "000000" }
      )
    end
  end

  class ListGenerator # rubocop:disable Metrics/ClassLength
    include Excel::Styles

    def initialize(list, companies, search_params, user) # rubocop:disable Metrics/MethodLength
      @list = list
      @companies = companies
      @search_params = search_params
      @user = user
      # Initialize data caches for batch-loaded data
      @procol_statuses = {}
      @effectifs = {}
      @social_debts = {}
      @score_entries_by_siren = {}
      @sjcf_companies = Set.new
      @tracking_statuses = {}
      @siege_establishments = {}
      @score_entries_by_company = {}
    end

    def generate
      package = Axlsx::Package.new
      workbook = package.workbook

      add_companies_sheet(workbook)
      add_filter_details_sheet(workbook) if @search_params.present?

      package.to_stream.read
    end

    private

    def add_companies_sheet(workbook)
      workbook.add_worksheet(name: "Entreprises") do |sheet|
        add_header_row(sheet)
        # Preload all data in batch before processing rows
        preload_all_data
        add_company_rows(sheet)
        format_sheet(sheet)
      end
    end

    def add_header_row(sheet) # rubocop:disable Metrics/MethodLength
      headers = [
        "Liste de détection",
        "Siren",
        "Siret",
        "Raison sociale",
        "Code département",
        "Année de création de l'entreprise",
        "Forme juridique",
        "Statut de procédure collective",
        "Dernier effectif entreprise",
        "Montant de la dette sociale",
        "Code secteur d'activité",
        "Libellé secteur d'activité",
        "Code NAF/APE",
        "Libellé NAF/APE",
        "Niveau d'alerte",
        "Fréquence d'alerte",
        "Score de défaillance",
        "Détail du score effectif",
        "Détail du score santé financière",
        "Détail du score dettes sociales",
        "Détail du score activité partielle",
        "Liste retraitée (Oui / Non)",
        "Délai de paiement Urssaf",
        "Entreprises récentes",
        "Accompagnement"
      ]
      # Reuse single style object instead of creating 25
      header_style_obj = header_style(sheet)
      sheet.add_row headers, style: Array.new(25, header_style_obj)
    end

    def add_company_rows(sheet) # rubocop:disable Metrics/MethodLength
      # Preload associations to avoid N+1 queries
      companies_with_data = @companies.includes(
        :establishments,
        :company_score_entries,
        establishments: %i[department establishment_trackings]
      )

      # Create style objects once and reuse
      row_style = centered_style(sheet)
      row_styles = Array.new(25, row_style)

      companies_with_data.each do |company|
        sheet.add_row prepare_company_row(company, sheet),
                      style: row_styles,
                      types: [:string] * 25
      end
    end

    def preload_all_data # rubocop:disable Metrics/MethodLength
      # Get all unique sirens and sirets from companies
      companies_array = @companies.includes(:establishments).to_a
      sirens = companies_array.filter_map(&:siren).uniq
      return if sirens.empty?

      # Preload siege establishments
      preload_siege_establishments(companies_array)

      # Preload score entries
      preload_score_entries(companies_array, sirens)

      # Preload procol statuses
      preload_procol_statuses(sirens)

      # Preload effectifs
      preload_effectifs(sirens)

      # Get all siege sirets for social debt queries
      siege_sirets = @siege_establishments.values.compact.filter_map(&:siret).uniq

      # Preload social debts
      preload_social_debts(siege_sirets)

      # Preload SJCF companies
      preload_sjcf_companies(sirens)

      # Preload tracking statuses
      preload_tracking_statuses(sirens)
    end

    def preload_siege_establishments(companies_array)
      # Build hash index for O(1) lookup instead of O(n) find
      companies_array.each do |company|
        # Use find_by on preloaded association (more efficient than find block)
        siege = company.establishments.find_by(siege: true)
        @siege_establishments[company.siren] = siege if siege
      end
    end

    def preload_score_entries(companies_array, sirens) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity
      # Load all score entries for all sirens
      all_entries = CompanyScoreEntry.where(siren: sirens).to_a

      # Build hash index for current list entries by company id
      current_list_entries = all_entries.select { |e| e.list_name == @list.label }
      current_list_entries_by_siren = current_list_entries.group_by(&:siren)

      # Index by company id for current list entries (O(1) lookup)
      companies_array.each do |company|
        entries = current_list_entries_by_siren[company.siren]
        @score_entries_by_company[company.id] = entries&.first if entries
      end

      # Index by siren for all entries (used for alert frequency and liste retraitée)
      all_entries.group_by(&:siren).each do |siren, entries|
        @score_entries_by_siren[siren] = entries
      end
    end

    def preload_procol_statuses(sirens) # rubocop:disable Metrics/MethodLength
      return if sirens.empty?

      current_date = Date.current

      # Process in batches to avoid very large IN clauses
      # This query replicates procol_at_date logic but filters by siren FIRST for performance
      sirens.each_slice(1000) do |siren_batch|
        placeholders = siren_batch.map { |_| "?" }.join(",")
        sql = <<-SQL.squish
          WITH last_action_procol AS (
            SELECT DISTINCT ON (siren, action_procol)
              siren, date_effet, action_procol, stade_procol, libelle_procol
            FROM osf_procols
            WHERE siren IN (#{placeholders})
              AND date_effet <= ?
            ORDER BY siren, action_procol, date_effet DESC
          )
          SELECT siren, libelle_procol
          FROM last_action_procol
          WHERE stade_procol != 'fin_procedure'
        SQL

        results = ActiveRecord::Base.connection.execute(
          ActiveRecord::Base.sanitize_sql([sql, *siren_batch, current_date])
        )

        results.each do |row|
          @procol_statuses[row["siren"]] = row["libelle_procol"]
        end
      end
    rescue StandardError
      # If query fails, all will default to "In Bonis" in format_procol_status
    end

    def preload_effectifs(sirens) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
      return if sirens.empty?

      # Use is_latest flag if available, otherwise get latest by periode
      latest_effectifs = OsfEntEffectif
                         .where(siren: sirens, is_latest: true)
                         .pluck(:siren, :effectif)

      latest_effectifs.each do |siren, effectif|
        @effectifs[siren] = effectif&.to_i || "-"
      end

      # For sirens without is_latest=true, get the latest by periode using SQL window function
      missing_sirens = sirens - @effectifs.keys
      return if missing_sirens.empty?

      # Use SQL window function to get only the latest effectif per siren (more efficient)
      # Process in batches to avoid very large IN clauses
      missing_sirens.each_slice(1000) do |siren_batch|
        placeholders = siren_batch.map { |_| "?" }.join(",")
        sql = <<-SQL.squish
          SELECT DISTINCT ON (siren) siren, effectif
          FROM osf_ent_effectifs
          WHERE siren IN (#{placeholders})
          ORDER BY siren, periode DESC
        SQL

        results = ActiveRecord::Base.connection.execute(
          ActiveRecord::Base.sanitize_sql([sql, *siren_batch])
        )

        results.each do |row|
          @effectifs[row["siren"]] = row["effectif"]&.to_i || "-"
        end
      end
    end

    def preload_social_debts(sirets)
      return if sirets.empty?

      debits = OsfDebit
               .where(siret: sirets, is_last: true)
               .pluck(:siret, :part_ouvriere, :part_patronale)

      debits.each do |siret, part_ouvriere, part_patronale|
        @social_debts[siret] = {
          part_ouvriere: part_ouvriere,
          part_patronale: part_patronale
        }
      end
    end

    def preload_sjcf_companies(sirens)
      return if sirens.empty?

      sjcf_sirens = SjcfCompany
                    .where(siren: sirens, libelle_liste: @list.label)
                    .pluck(:siren)

      @sjcf_companies = Set.new(sjcf_sirens)
    end

    def preload_tracking_statuses(sirens) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
      return if sirens.empty?

      # Get all establishments for these sirens
      establishments = Establishment.where(siren: sirens).pluck(:siren, :siret)
      return if establishments.empty?

      sirets = establishments.filter_map(&:last).uniq
      return if sirets.empty?

      # Get all trackings for these establishments
      trackings = EstablishmentTracking
                  .where(establishment_siret: sirets)
                  .kept
                  .pluck(:establishment_siret, :state)

      # Create a hash for quick lookup: siret => [states]
      trackings_by_siret = trackings.group_by(&:first).transform_values { |v| v.map(&:last) }

      # Group trackings by siren and calculate status
      establishments_by_siren = establishments.group_by(&:first)
      establishments_by_siren.each do |siren, siren_establishments|
        states = []
        siren_establishments.each do |_, siret| # rubocop:disable Style/HashEachMethods
          states.concat(trackings_by_siret[siret] || [])
        end

        next if states.empty?

        @tracking_statuses[siren] = if states.include?("in_progress")
                                      "Accompagnement en cours"
                                    elsif states.include?("under_surveillance")
                                      "Accompagnement sous surveillance"
                                    elsif states.include?("completed")
                                      "Accompagnement terminé"
                                    else
                                      "Pas d'accompagnement"
                                    end
      end
    end

    def prepare_company_row(company, _sheet) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
      # Use preloaded data instead of querying
      siege_establishment = @siege_establishments[company.siren]
      # Get score entry for current list specifically
      score_entry = @score_entries_by_company[company.id]
      if score_entry.nil?
        entries = @score_entries_by_siren[company.siren] || []
        score_entry = entries.find { |e| e.list_name == @list.label }
      end

      [
        @list.label, # Campagne
        company.siren,
        siege_establishment&.siret || "-",
        company.raison_sociale || "-",
        company.department&.code || "-",
        format_creation_year(company.creation),
        format_statut_juridique(company.libelle_categorie_juridique),
        format_procol_status(company.siren),
        format_last_effectif(company.siren),
        format_social_debt(company.siren, siege_establishment),
        format_insee_sector(company),
        company.libelle_activite_principale || "-",
        format_naf_activity(company),
        company.libelle_naf_section || "-",
        format_alert_level(score_entry),
        format_alert_frequency(company.siren),
        format_score(score_entry&.score),
        format_score_detail(score_entry, "Variation-de-l'effectif-de-l'entreprise"),
        format_score_detail(score_entry, "Données-financières"),
        format_score_detail(score_entry, "Dettes-sociales"),
        format_score_detail(score_entry, "Recours-à-l'activité-partielle"),
        format_sjcf(company.siren),
        format_delai_urssaf(siege_establishment),
        format_entreprise_recente(company.creation),
        format_tracking_status(company.siren)
      ]
    end

    def format_creation_year(creation_date)
      creation_date&.year || "-"
    end

    def format_statut_juridique(statut)
      statut || "-"
    end

    def format_procol_status(siren)
      @procol_statuses[siren] || "In Bonis"
    end

    def format_last_effectif(siren)
      @effectifs[siren] || "-"
    end

    def format_social_debt(_siren, siege_establishment)
      return "-" unless siege_establishment

      debt = @social_debts[siege_establishment.siret]
      return "-" unless debt

      total = (debt[:part_ouvriere].to_f + debt[:part_patronale].to_f)
      total.positive? ? total.round(2) : "-"
    end

    def format_insee_sector(company)
      company.naf_section || "-"
    end

    def format_naf_activity(company)
      company.naf_code || "-"
    end

    def format_alert_level(score_entry)
      return "-" unless score_entry&.alert

      case score_entry.alert.downcase
      when "alerte seuil f1"
        "Alerte élevée"
      when "alerte seuil f2"
        "Alerte modérée"
      else
        "-"
      end
    end

    def format_alert_frequency(siren)
      # Use preloaded score entries data
      entries = @score_entries_by_siren[siren] || []
      return "-" if entries.empty?

      # Check if company appears in other lists (excluding current list)
      other_entries_exist = entries.any? { |entry| entry.list_name != @list.label }

      # If no other entries, it's a first alert; otherwise nothing
      other_entries_exist ? "-" : "1ère alerte"
    end

    def format_score(score)
      return "-" unless score

      score.to_f.round
    end

    def format_score_detail(score_entry, key)
      return "-" unless score_entry&.macro_expl

      value = score_entry.macro_expl[key]
      return "-" unless value

      value.to_f.round
    end

    def format_sjcf(siren)
      @sjcf_companies.include?(siren) ? "Oui" : "Non"
    end

    def format_delai_urssaf(siege_establishment)
      return "-" unless siege_establishment

      # Use preloaded social debt data (same logic as active_dette_urssaf)
      debt = @social_debts[siege_establishment.siret]
      return "Non" unless debt

      has_delai = debt[:part_ouvriere].to_f.positive? || debt[:part_patronale].to_f.positive?
      has_delai ? "Oui" : "Non"
    end

    def format_entreprise_recente(creation_date)
      return "-" unless creation_date

      three_years_ago = Date.current - 3.years
      creation_date >= three_years_ago ? "Oui" : "Non"
    end

    def format_tracking_status(siren)
      # Use preloaded tracking status
      @tracking_statuses[siren] || "Pas d'accompagnement"
    end

    def format_sheet(sheet)
      autosize_columns(sheet)
      apply_borders(sheet)
    end

    def autosize_columns(sheet)
      return if sheet.rows.empty?

      column_count = sheet.rows.first&.cells&.size.to_i
      return if column_count <= 2

      # Autosize all columns
      sheet.column_widths(*Array.new(column_count, nil))
    end

    def apply_borders(sheet)
      return if sheet.rows.empty?

      last_row = sheet.rows.size
      last_column = sheet.rows.first&.cells&.size.to_i

      if last_column.positive? && last_row > 1
        range = "A1:#{('A'.ord + last_column - 1).chr}#{last_row}"
        sheet.add_style(range, border: { style: :thick, color: "000000" })
      end
    end

    def add_filter_details_sheet(workbook) # rubocop:disable Metrics/MethodLength
      workbook.add_worksheet(name: "Filtres") do |sheet|
        sheet.add_row %w[Filtre Valeur]
        @search_params.each do |key, value|
          next if value.blank?

          formatted_value = if value.is_a?(Array)
                              value.join(", ")
                            else
                              value.to_s
                            end
          sheet.add_row [format_filter_label(key), formatted_value]
        end
      end
    end

    def format_filter_label(key) # rubocop:disable Metrics/MethodLength
      {
        "q" => "Recherche",
        "ca_min" => "CA minimum",
        "effectif_min" => "Effectif minimum",
        "score_min" => "Score minimum",
        "dette_sociale_min" => "Dette sociale minimum",
        "action_procol" => "Action procédure collective",
        "frequence_alerte" => "Fréquence d'alerte",
        "niveau_alerte" => "Niveau d'alerte",
        "premieres_alertes" => "Premières alertes",
        "sans_entreprises_recentes" => "Sans entreprises récentes",
        "departement_in" => "Départements",
        "forme_juridique" => "Forme juridique",
        "section_activite_principale" => "Section activité principale"
      }[key.to_s] || key.to_s.humanize
    end
  end
end
