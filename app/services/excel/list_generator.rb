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
      @has_delai_urssaf = Set.new
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

    def preload_all_data
      # Get all sirens from the companies query (without loading all companies into memory)
      sirens = @companies.pluck(:siren).compact.uniq
      return if sirens.empty?

      # Single massive query to get all data at once using CTEs
      load_all_data_in_single_query(sirens)
    end

    def load_all_data_in_single_query(sirens) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
      current_date = Date.current
      list_label = @list.label
      @alert_frequencies = {}

      # Build SQL with VALUES clause for target sirens
      # PostgreSQL can handle large IN clauses efficiently, but VALUES is even better
      values_placeholders = sirens.map { |_| "(?)" }.join(",")

      sql = <<~SQL
        WITH target_sirens AS (
          SELECT siren::VARCHAR(9)
          FROM (VALUES #{values_placeholders}) AS t(siren)
        ),
        siege_establishments AS (
          SELECT DISTINCT ON (e.siren) e.siren, e.siret
          FROM establishments e
          INNER JOIN target_sirens ts ON e.siren = ts.siren
          WHERE e.siege = true
          ORDER BY e.siren, e.siret
        ),
        current_score_entries AS (
          SELECT DISTINCT ON (cse.siren) cse.siren, cse.score, cse.alert, cse.macro_expl
          FROM company_score_entries cse
          INNER JOIN target_sirens ts ON cse.siren = ts.siren
          WHERE cse.list_name = ?
          ORDER BY cse.siren, cse.created_at DESC
        ),
        procol_statuses AS (
          WITH last_action_procol AS (
            SELECT DISTINCT ON (op.siren, op.action_procol) op.siren, op.libelle_procol, op.stade_procol
            FROM osf_procols op
            INNER JOIN target_sirens ts ON op.siren = ts.siren
            WHERE op.date_effet <= ?
            ORDER BY op.siren, op.action_procol, op.date_effet DESC
          )
          SELECT siren, libelle_procol
          FROM last_action_procol
          WHERE stade_procol != 'fin_procedure'
        ),
        all_effectifs AS (
          SELECT DISTINCT ON (oee.siren) oee.siren, oee.effectif
          FROM osf_ent_effectifs oee
          INNER JOIN target_sirens ts ON oee.siren = ts.siren
          ORDER BY oee.siren, oee.is_latest DESC NULLS LAST, oee.periode DESC
        ),
        all_establishments AS (
          SELECT DISTINCT e.siren, e.siret
          FROM establishments e
          INNER JOIN target_sirens ts ON e.siren = ts.siren
        ),
        social_debts AS (
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
          INNER JOIN target_sirens ts ON sc.siren = ts.siren
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
        )
        SELECT ts.siren, se.siret AS siege_siret, cse.score, cse.alert, cse.macro_expl,
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
        ORDER BY ts.siren
      SQL

      # Execute the query with all parameters
      # Parameters order: sirens (VALUES), list_label (current_score_entries), current_date (procol),
      #   list_label (sjcf_companies), list_date (delai_urssaf_companies), list_label (is_first_alert)
      list_date = @list.list_date || Date.current
      all_params = sirens + [list_label, current_date, list_label, list_date, list_label]
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
      end

      # Load all score entries for companies that don't have current list entries
      missing_sirens = sirens - @score_entries_by_siren.keys
      return unless missing_sirens.any?

      all_entries = CompanyScoreEntry.where(siren: missing_sirens).pluck(:siren, :list_name)
      all_entries.group_by(&:first).each do |siren, entries|
        @score_entries_by_siren[siren] = entries.map { |_, list_name| { list_name: list_name } }
      end
    end

    def prepare_company_row(company, _sheet) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
      # Use preloaded data instead of querying
      siege_siret = @siege_establishments[company.siren]
      siege_establishment = siege_siret ? company.establishments.find_by(siret: siege_siret) : nil

      # Get score entry for current list specifically (always a hash from single query)
      score_entry = @score_entries_by_company[company.siren]

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
        format_score(score_entry ? score_entry[:score] : nil),
        format_score_detail(score_entry, "Variation-de-l'effectif-de-l'entreprise"),
        format_score_detail(score_entry, "Données-financières"),
        format_score_detail(score_entry, "Dettes-sociales"),
        format_score_detail(score_entry, "Recours-à-l'activité-partielle"),
        format_sjcf(company.siren),
        format_delai_urssaf(company.siren),
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

    def format_social_debt(siren, _siege_establishment)
      debt = @social_debts[siren]
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

    def format_score(score)
      return "-" unless score

      score.to_f.round
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
