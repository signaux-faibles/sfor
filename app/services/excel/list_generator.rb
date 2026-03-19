# app/services/excel/list_generator.rb
# rubocop:disable all
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

    def initialize(list, companies, search_params, user)
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
      @has_delai_urssaf = Set.new
      @company_data = {} # Cache for company metadata (raison_sociale, department, etc.)
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
        "Détail du score effectif",
        "Détail du score santé financière",
        "Détail du score dettes sociales",
        "Détail du score activité partielle",
        "Liste retraitée (Oui / Non)",
        "Délai de paiement Urssaf",
        "Entreprises récentes",
        "Accompagnement"
      ]
      # Reuse single style object instead of creating 24
      header_style_obj = header_style(sheet)
      sheet.add_row headers, style: Array.new(24, header_style_obj)
    end

    def add_company_rows(sheet)
      # Get sirens in the same order as the companies query (if order matters)
      # Otherwise just use the sirens from our cache
      sirens = @companies.pluck(:siren).compact.uniq
      # Sort by score descending (nil scores last)
      sirens.sort_by! do |siren|
        score_value = @score_entries_by_company.dig(siren, :score)&.to_f
        [-(score_value || -Float::INFINITY), siren]
      end

      # Create style objects once and reuse
      row_style = centered_style(sheet)
      row_styles = Array.new(24, row_style)

      sirens.each do |siren|
        sheet.add_row prepare_company_row(siren, sheet),
                      style: row_styles,
                      types: [:string] * 24
      end
    end

    def preload_all_data
      # Get all sirens from the companies query (without loading all companies into memory)
      sirens = @companies.pluck(:siren).compact.uniq
      return if sirens.empty?

      # Single massive query to get all data at once using CTEs
      load_all_data_in_single_query(sirens)
    end

    def load_all_data_in_single_query(sirens) # rubocop:disable Metrics/MethodLength
      current_date = Date.current
      list_label = @list.label
      @alert_frequencies = {}

      # Build SQL with a single VALUES clause for target sirens.
      # All downstream CTEs join against target_sirens instead of repeating the siren array.
      # This keeps the total bind parameter count at N + 5 (vs the old 8N + 3), which avoids
      # PostgreSQL's hard limit of 65,535 parameters (~8k-company exports would crash otherwise).
      values_placeholders = sirens.map { |_| "(?)" }.join(",")

      sql = <<~SQL
        WITH target_sirens AS (
          SELECT siren::VARCHAR(9)
          FROM (VALUES #{values_placeholders}) AS t(siren)
        ),
        siege_establishments AS (
          SELECT DISTINCT ON (e.siren) e.siren, e.siret
          FROM establishments e
          INNER JOIN target_sirens ts_filter ON ts_filter.siren = e.siren
          WHERE e.siege = true
          ORDER BY e.siren, e.siret
        ),
        current_score_entries AS (
          SELECT DISTINCT ON (cse.siren) cse.siren, cse.score, cse.alert, cse.macro_expl
          FROM company_score_entries cse
          INNER JOIN target_sirens ts_filter ON ts_filter.siren = cse.siren
          WHERE cse.list_name = ?
          ORDER BY cse.siren, cse.created_at DESC
        ),
        procol_statuses AS (
          SELECT procol.siren, procol.libelle_procol
          FROM procol_at_date(?) AS procol
          INNER JOIN target_sirens ts_filter ON ts_filter.siren = procol.siren
        ),
        all_effectifs AS MATERIALIZED (
          SELECT oee.siren, oee.effectif
          FROM osf_ent_effectifs oee
          INNER JOIN target_sirens ts_filter ON ts_filter.siren = oee.siren
          WHERE oee.is_latest = true
        ),
        all_establishments AS MATERIALIZED (
          SELECT DISTINCT e.siren, e.siret
          FROM establishments e
          INNER JOIN target_sirens ts_filter ON ts_filter.siren = e.siren
        ),
        social_debts AS MATERIALIZED (
          SELECT ae.siren,
            COALESCE(SUM(od.part_ouvriere), 0) AS part_ouvriere,
            COALESCE(SUM(od.part_patronale), 0) AS part_patronale
          FROM all_establishments ae
          LEFT JOIN osf_debits od ON od.siret = ae.siret AND od.is_last = true
          GROUP BY ae.siren
        ),
        sjcf_companies AS (
          SELECT DISTINCT sc.siren
          FROM sjcf_companies sc
          INNER JOIN target_sirens ts_filter ON ts_filter.siren = sc.siren
          WHERE sc.libelle_liste = ?
        ),
        tracking_states AS (
          SELECT ae.siren, et.state
          FROM all_establishments ae
          INNER JOIN establishment_trackings et ON et.establishment_siret = ae.siret
          WHERE et.discarded_at IS NULL
        ),
        tracking_statuses AS (
          SELECT siren,
            CASE
              WHEN bool_or(state = 'in_progress') THEN 'Accompagnement en cours'
              WHEN bool_or(state = 'under_surveillance') THEN 'Accompagnement sous surveillance'
              WHEN bool_or(state = 'completed') THEN 'Accompagnement terminé'
              ELSE 'Pas d''accompagnement'
            END AS status
          FROM tracking_states
          GROUP BY siren
        ),
        delai_urssaf_companies AS (
          SELECT DISTINCT ae.siren
          FROM all_establishments ae
          INNER JOIN osf_delais od ON od.siret = ae.siret
          WHERE od.date_echeance > COALESCE(?, CURRENT_DATE)
        ),
        company_metadata AS (
          SELECT c.siren, c.raison_sociale, c.department, c.creation,
            c.libelle_categorie_juridique, c.naf_section, c.libelle_activite_principale,
            c.naf_code, c.libelle_naf_section
          FROM companies c
          INNER JOIN target_sirens ts_filter ON ts_filter.siren = c.siren
        )
        SELECT ts.siren, se.siret AS siege_siret, cse.score, cse.alert, cse.macro_expl,
          cm.raison_sociale, cm.department, cm.creation, cm.libelle_categorie_juridique,
          cm.naf_section, cm.libelle_activite_principale, cm.naf_code, cm.libelle_naf_section,
          CASE WHEN EXISTS (SELECT 1 FROM company_score_entries ase WHERE ase.siren = ts.siren AND ase.list_name != ?) THEN false ELSE true END AS is_first_alert,
          COALESCE(ps.libelle_procol, 'In Bonis') AS procol_status,
          COALESCE(ae.effectif, 0) AS effectif,
          sd.part_ouvriere, sd.part_patronale,
          CASE WHEN sc.siren IS NOT NULL THEN true ELSE false END AS is_sjcf,
          COALESCE(ts_status.status, 'Pas d''accompagnement') AS tracking_status,
          CASE WHEN du.siren IS NOT NULL THEN true ELSE false END AS has_delai_urssaf
        FROM target_sirens ts
        LEFT JOIN siege_establishments se ON ts.siren = se.siren
        LEFT JOIN current_score_entries cse ON ts.siren = cse.siren
        LEFT JOIN procol_statuses ps ON ts.siren = ps.siren
        LEFT JOIN all_effectifs ae ON ts.siren = ae.siren
        LEFT JOIN social_debts sd ON ts.siren = sd.siren
        LEFT JOIN sjcf_companies sc ON ts.siren = sc.siren
        LEFT JOIN tracking_statuses ts_status ON ts.siren = ts_status.siren
        LEFT JOIN delai_urssaf_companies du ON ts.siren = du.siren
        LEFT JOIN company_metadata cm ON ts.siren = cm.siren
        ORDER BY ts.siren
      SQL

      # Parameters order (matching SQL placeholders in order):
      #   1. sirens (VALUES clause) - N parameters  [only occurrence of sirens]
      #   2. list_label (current_score_entries WHERE clause)
      #   3. current_date (procol_statuses function argument)
      #   4. list_label (sjcf_companies WHERE clause)
      #   5. list_date (delai_urssaf_companies WHERE clause)
      #   6. list_label (is_first_alert EXISTS subquery)
      # Total: N + 5 parameters (was 8N + 3, which broke at ~8k companies)
      list_date = @list.list_date || Date.current
      all_params = sirens +        # VALUES (sirens bound only once)
                   [list_label] +  # current_score_entries WHERE
                   [current_date] + # procol_statuses function argument
                   [list_label] +  # sjcf_companies WHERE
                   [list_date] +   # delai_urssaf_companies WHERE
                   [list_label]    # is_first_alert EXISTS subquery
      sanitized_sql = ActiveRecord::Base.sanitize_sql_array([sql] + all_params)
      Rails.logger.debug "SQL Query: #{sanitized_sql}"

      results = ActiveRecord::Base.connection.exec_query(sanitized_sql)

      # Populate all caches from single query result
      results.each do |row| # rubocop:disable Metrics/BlockLength
        siren = row.is_a?(Hash) ? row["siren"] : row[:siren]

        # Siege establishment siret (we'll load the object when needed)
        @siege_establishments[siren] = row["siege_siret"] if row["siege_siret"]

        # Score entry data for current list
        if row["score"]
          macro_expl = if row["macro_expl"]
                         row["macro_expl"].is_a?(String) ? JSON.parse(row["macro_expl"]) : row["macro_expl"]
                       end
          score_data = {
            score: row["score"],
            alert: row["alert"],
            macro_expl: macro_expl,
            list_name: list_label
          }
          @score_entries_by_siren[siren] ||= []
          @score_entries_by_siren[siren] << score_data
          # Also store for current list lookup (by siren for single query approach)
          @score_entries_by_company[siren] = score_data
        end

        # Procol status
        @procol_statuses[siren] = row["procol_status"] if row["procol_status"]

        # Effectif
        effectif = row["effectif"]
        @effectifs[siren] = effectif&.to_i || "-" if effectif&.to_i&.positive?

        # Social debt (keyed by siren - sum of all establishments)
        if row["part_ouvriere"] || row["part_patronale"]
          @social_debts[siren] = {
            part_ouvriere: row["part_ouvriere"] || 0,
            part_patronale: row["part_patronale"] || 0
          }
        end

        # SJCF
        @sjcf_companies.add(siren) if row["is_sjcf"]

        # Tracking status
        @tracking_statuses[siren] = row["tracking_status"] if row["tracking_status"]

        # Alert frequency
        @alert_frequencies[siren] = row["is_first_alert"] ? "1ère alerte" : "-"

        # Delai URSSAF
        @has_delai_urssaf.add(siren) if row["has_delai_urssaf"]

        # Company metadata (convert date strings to Date objects)
        creation_date = row["creation"]
        creation_date = creation_date.to_date if creation_date.is_a?(String)

        @company_data[siren] = {
          raison_sociale: row["raison_sociale"],
          department: row["department"],
          creation: creation_date,
          libelle_categorie_juridique: row["libelle_categorie_juridique"],
          naf_section: row["naf_section"],
          libelle_activite_principale: row["libelle_activite_principale"],
          naf_code: row["naf_code"],
          libelle_naf_section: row["libelle_naf_section"]
        }
      end

      # Load all score entries for companies that don't have current list entries
      missing_sirens = sirens - @score_entries_by_siren.keys
      return unless missing_sirens.any?

      all_entries = CompanyScoreEntry.where(siren: missing_sirens).pluck(:siren, :list_name)
      all_entries.group_by(&:first).each do |siren, entries|
        @score_entries_by_siren[siren] = entries.map { |_, list_name| { list_name: list_name } }
      end
    end

    def prepare_company_row(siren, _sheet) # rubocop:disable Metrics/MethodLength
      # Use preloaded data instead of querying
      siege_siret = @siege_establishments[siren]
      company_data = @company_data[siren] || {}

      # Get score entry for current list specifically (always a hash from single query)
      score_entry = @score_entries_by_company[siren]

      # Get department code - company_data[:department] is already the code string
      department_code = company_data[:department] || "-"

      [
        @list.label, # Campagne
        siren,
        siege_siret || "-",
        company_data[:raison_sociale] || "-",
        department_code,
        format_creation_year(company_data[:creation]),
        format_statut_juridique(company_data[:libelle_categorie_juridique]),
        format_procol_status(siren),
        format_last_effectif(siren),
        format_social_debt(siren, nil),
        format_insee_sector(company_data),
        company_data[:libelle_naf_section] || "-",
        format_naf_activity(company_data),
        company_data[:libelle_activite_principale] || "-",
        format_alert_level(score_entry),
        format_alert_frequency(siren),
        format_score_detail(score_entry, "Variation-de-l'effectif-de-l'entreprise"),
        format_score_detail(score_entry, "Données-financières"),
        format_score_detail(score_entry, "Dettes-sociales"),
        format_score_detail(score_entry, "Recours-à-l'activité-partielle"),
        format_sjcf(siren),
        format_delai_urssaf(siren),
        format_entreprise_recente(company_data[:creation]),
        format_tracking_status(siren)
      ]
    end

    def format_creation_year(creation_date)
      return "-" unless creation_date

      # Convert string to Date if needed (exec_query returns dates as strings)
      date = creation_date.is_a?(String) ? creation_date.to_date : creation_date
      date.year || "-"
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

    def format_social_debt(siren, _siege_establishment)
      debt = @social_debts[siren]
      return "-" unless debt

      total = (debt[:part_ouvriere].to_f + debt[:part_patronale].to_f)
      total.positive? ? total.round(2) : "-"
    end

    def format_insee_sector(company_data)
      company_data[:naf_section] || "-"
    end

    def format_naf_activity(company_data)
      company_data[:naf_code] || "-"
    end

    def format_alert_level(score_entry)
      return "-" unless score_entry && score_entry[:alert]

      case score_entry[:alert].downcase
      when "alerte seuil f1"
        "Alerte élevée"
      when "alerte seuil f2"
        "Alerte modérée"
      else
        "-"
      end
    end

    def format_alert_frequency(siren)
      # Use preloaded alert frequency from single query
      return @alert_frequencies[siren] if @alert_frequencies&.key?(siren)

      # Use preloaded score entries data if alert frequency not in cache
      entries = @score_entries_by_siren[siren] || []
      return "-" if entries.empty?

      # Check if company appears in other lists (excluding current list)
      other_entries_exist = entries.any? { |entry| entry[:list_name] != @list.label }

      # If no other entries, it's a first alert; otherwise nothing
      other_entries_exist ? "-" : "1ère alerte"
    end

    def format_score_detail(score_entry, key)
      return "-" unless score_entry && score_entry[:macro_expl]

      value = score_entry[:macro_expl][key]
      return "-" unless value

      value.to_f.round
    end

    def format_sjcf(siren)
      @sjcf_companies.include?(siren) ? "Oui" : "Non"
    end

    def format_delai_urssaf(siren)
      # Check if company has any establishment with OsfDelai where date_echeance > list_date
      @has_delai_urssaf.include?(siren) ? "Oui" : "Non"
    end

    def format_entreprise_recente(creation_date)
      return "-" unless creation_date

      # Convert string to Date if needed (exec_query returns dates as strings)
      date = creation_date.is_a?(String) ? creation_date.to_date : creation_date
      date >= entreprises_recentes_filter_date ? "Oui" : "Non"
    end

    def entreprises_recentes_filter_date
      @entreprises_recentes_filter_date ||= AppSetting.current&.entreprises_recentes_filter_date || (Date.current - 3.years)
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

    def add_filter_details_sheet(workbook)
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

    def format_filter_label(key)
      {
        "q" => "Recherche",
        "ca_min" => "CA minimum",
        "effectif_min" => "Effectif minimum",
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
