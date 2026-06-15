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
        border: { style: :thick, color: "000000" }
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
      @sjcf_companies = Set.new
      @tracking_statuses = {}
      @siege_establishments = {}
      @score_entries_by_company = {}
      @has_delai_urssaf = Set.new
      @company_data = {} # Cache for company metadata (raison_sociale, department, etc.)
      @inpi_bce_ratios = {}
    end

    def generate
      package = Axlsx::Package.new(use_shared_strings: false)
      workbook = package.workbook

      add_companies_sheet(workbook)
      add_filter_details_sheet(workbook) if @search_params.present?

      t = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      result = package.to_stream.read
      Rails.logger.info "[ListGenerator] to_stream.read: #{(Process.clock_gettime(Process::CLOCK_MONOTONIC) - t).round(2)}s"
      result
    end

    private

    def add_companies_sheet(workbook)
      workbook.add_worksheet(name: "Entreprises") do |sheet|
        add_header_row(sheet)

        t = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        preload_all_data
        Rails.logger.info "[ListGenerator] preload_all_data (#{@company_data.size} companies): #{(Process.clock_gettime(Process::CLOCK_MONOTONIC) - t).round(2)}s"

        t = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        add_company_rows(sheet)
        Rails.logger.info "[ListGenerator] add_company_rows: #{(Process.clock_gettime(Process::CLOCK_MONOTONIC) - t).round(2)}s"
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
        "Liste retraitée (Oui / Non)",
        "Délai de paiement Urssaf",
        "Entreprises récentes",
        "Accompagnement",
        "Taux endettement",
        "CA",
        "Résultat net",
        "Résultat d'exploitation",
        "Ratio de liquidité"
      ]
      # Reuse single style object instead of creating 25
      header_style_obj = header_style(sheet)
      sheet.add_row headers, style: Array.new(25, header_style_obj)
    end

    def add_company_rows(sheet)
      # Use sirens already loaded into @company_data by preload_all_data — no extra DB query.
      sirens = @company_data.keys
      # Sort by score descending (nil scores last)
      sirens.sort_by! do |siren|
        score_value = @score_entries_by_company.dig(siren, :score)&.to_f
        [-(score_value || -Float::INFINITY), siren]
      end

      sirens.each do |siren|
        sheet.add_row prepare_company_row(siren, sheet)
      end
    end

    def preload_all_data
      # Use the AR relation as a subquery — no pluck needed. The CTE result
      # populates @company_data, whose keys are then used by add_company_rows.
      load_all_data_in_single_query
    end

    def load_all_data_in_single_query # rubocop:disable Metrics/MethodLength
      list_label = @list.label
      @alert_frequencies = {}

      # Embed the AR relation as a subquery for target_sirens instead of a VALUES clause.
      # Benefits vs the previous VALUES approach:
      #   - Eliminates N bind parameters (was N+5 total, now just 5 scalars regardless of list size)
      #   - No large SQL string to build and parse in Ruby
      #   - No separate pluck(:siren) DB round-trip
      #   - MATERIALIZED forces a single evaluation; without it PostgreSQL 12+ could inline
      #     and re-execute the subquery once per downstream CTE reference.
      sirens_subquery = @companies.select(:siren).to_sql

      sql = <<~SQL
        WITH target_sirens AS MATERIALIZED (
          #{sirens_subquery}
        ),
        list_scores AS (
          SELECT cl.siren, cl.score, cl.alert
          FROM company_lists cl
          WHERE cl.list_id = ?
        ),
        sjcf_companies AS (
          SELECT DISTINCT sc.siren
          FROM sjcf_companies sc
          INNER JOIN target_sirens ts_filter ON ts_filter.siren = sc.siren
          WHERE sc.libelle_liste = ?
        ),
        company_metadata AS (
          SELECT c.siren, c.siret_siege, c.social_debt_total, c.latest_effectif,
            c.current_procol_status, c.raison_sociale, c.department, c.creation,
            c.libelle_categorie_juridique, c.naf_section, c.libelle_activite_principale,
            c.naf_code, c.libelle_naf_section,
            COALESCE(c.tracking_status, 'Pas d''accompagnement') AS tracking_status,
            (c.delai_urssaf_until IS NOT NULL AND c.delai_urssaf_until > CAST(? AS date)) AS has_delai_urssaf
          FROM companies c
          INNER JOIN target_sirens ts_filter ON ts_filter.siren = c.siren
        ),
        first_alert_sirens AS (
          SELECT ts_filter.siren
          FROM target_sirens ts_filter
          INNER JOIN list_scores ls_current ON ls_current.siren = ts_filter.siren
          WHERE ls_current.alert IN (?)
            AND NOT EXISTS (
              SELECT 1 FROM company_score_entries cse_other
              INNER JOIN lists l ON l.label = cse_other.list_name
              WHERE cse_other.siren = ts_filter.siren
                AND cse_other.list_name != ?
                AND l.list_date > ?
                AND l.list_date < ?
                AND cse_other.alert IN (?)
            )
        ),
        latest_inpi_bce_ratios AS (
          SELECT DISTINCT ON (ibr.siren)
            ibr.siren,
            ibr.taux_d_endettement,
            ibr.chiffre_d_affaires,
            ibr.resultat_net,
            ibr.ebit,
            ibr.ratio_de_liquidite
          FROM inpi_bce_ratios ibr
          INNER JOIN target_sirens ts_filter ON ts_filter.siren = ibr.siren
          ORDER BY ibr.siren,
            ibr.date_cloture_exercice DESC,
            CASE ibr.type_bilan
              WHEN 'K' THEN 1
              WHEN 'C' THEN 2
              WHEN 'S' THEN 3
              ELSE 4
            END,
            ibr.id DESC
        )
        SELECT ts.siren, cm.siret_siege, ls.score, ls.alert,
          cm.raison_sociale, cm.department, cm.creation, cm.libelle_categorie_juridique,
          cm.naf_section, cm.libelle_activite_principale, cm.naf_code, cm.libelle_naf_section,
          CASE WHEN fa.siren IS NOT NULL THEN true ELSE false END AS is_first_alert,
          COALESCE(cm.current_procol_status, 'In Bonis') AS procol_status,
          COALESCE(cm.latest_effectif, 0) AS effectif,
          cm.social_debt_total,
          CASE WHEN sc.siren IS NOT NULL THEN true ELSE false END AS is_sjcf,
          cm.tracking_status,
          cm.has_delai_urssaf,
          libr.taux_d_endettement,
          libr.chiffre_d_affaires,
          libr.resultat_net,
          libr.ebit,
          libr.ratio_de_liquidite
        FROM target_sirens ts
        LEFT JOIN list_scores ls ON ts.siren = ls.siren
        LEFT JOIN sjcf_companies sc ON ts.siren = sc.siren
        LEFT JOIN company_metadata cm ON ts.siren = cm.siren
        LEFT JOIN first_alert_sirens fa ON ts.siren = fa.siren
        LEFT JOIN latest_inpi_bce_ratios libr ON ts.siren = libr.siren
        ORDER BY ts.siren
      SQL

      # Parameters order (matching SQL placeholders in order) — sirens are in the
      # embedded AR subquery, not as bind params, so only 8 values remain:
      #   1. @list.id   (list_scores WHERE list_id = ?)
      #   2. list_label (sjcf_companies WHERE clause)
      #   3. list_date  (company_metadata: delai_urssaf_until > ?)
      #   4. MEANINGFUL_ALERT_VALUES (first_alert_sirens: current alert required)
      #   5. list_label (first_alert_sirens: list_name != current list)
      #   6. cutoff_date (first_alert_sirens: l.list_date > 18-month window start)
      #   7. list_date  (first_alert_sirens: l.list_date < current list date)
      #   8. F1/F2 alerts (first_alert_sirens: prior detection; Plans/Ratios/Pas d'alerte excluded)
      list_date = @list.list_date || Date.current
      cutoff_date = list_date - 18.months
      all_params = [@list.id,      # list_scores WHERE list_id = ?
                    list_label,    # sjcf_companies WHERE
                    list_date,     # company_metadata: delai_urssaf_until > ?
                    CompanyList::MEANINGFUL_ALERT_VALUES, # first_alert_sirens: current alert
                    list_label,    # first_alert_sirens: list_name !=
                    cutoff_date,   # first_alert_sirens: l.list_date >
                    list_date,     # first_alert_sirens: l.list_date <
                    CompanyList::STANDARD_ALERT_VALUES]
      sanitized_sql = ActiveRecord::Base.sanitize_sql_array([sql] + all_params)
      Rails.logger.info "[ListGenerator] Full query for EXPLAIN ANALYZE:\nEXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)\n#{sanitized_sql};"

      t_db = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      results = ActiveRecord::Base.transaction do
        # random_page_cost=1.1: tells planner SSD random I/O ≈ sequential I/O,
        # preventing it from choosing full seq scans of 32M-row tables over index probes.
        # enable_mergejoin=off: prevents the bad merge join plan on company_metadata
        # that reads all 22M companies in index order.
        ActiveRecord::Base.connection.execute("SET LOCAL random_page_cost = 1.1")
        ActiveRecord::Base.connection.execute("SET LOCAL enable_mergejoin = off")
        ActiveRecord::Base.connection.exec_query(sanitized_sql)
      end
      Rails.logger.info "[ListGenerator] exec_query: #{(Process.clock_gettime(Process::CLOCK_MONOTONIC) - t_db).round(2)}s (#{results.length} rows)"

      t_iter = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      # Populate all caches from single query result
      results.each do |row| # rubocop:disable Metrics/BlockLength
        siren = row.is_a?(Hash) ? row["siren"] : row[:siren]

        # Siege siret — read directly from companies.siret_siege
        @siege_establishments[siren] = row["siret_siege"] if row["siret_siege"]

        # Score entry data for current list — JSONB values extracted in SQL, no JSON.parse needed
        if row["score"]
          @score_entries_by_company[siren] = {
            score: row["score"],
            alert: row["alert"]
          }
        end

        # Procol status
        @procol_statuses[siren] = row["procol_status"] if row["procol_status"]

        # Effectif
        effectif = row["effectif"]
        @effectifs[siren] = effectif&.to_i || "-" if effectif&.to_i&.positive?

        # Social debt — pre-aggregated on companies.social_debt_total
        @social_debts[siren] = row["social_debt_total"].to_f if row["social_debt_total"]

        # SJCF
        @sjcf_companies.add(siren) if row["is_sjcf"]

        # Tracking status
        @tracking_statuses[siren] = row["tracking_status"] if row["tracking_status"]

        # Alert frequency
        @alert_frequencies[siren] = row["is_first_alert"] ? "1ère alerte" : "-"

        # Delai URSSAF
        @has_delai_urssaf.add(siren) if row["has_delai_urssaf"]

        @inpi_bce_ratios[siren] = {
          taux_d_endettement: row["taux_d_endettement"],
          chiffre_d_affaires: row["chiffre_d_affaires"],
          resultat_net: row["resultat_net"],
          ebit: row["ebit"],
          ratio_de_liquidite: row["ratio_de_liquidite"]
        }

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
      Rails.logger.info "[ListGenerator] results.each: #{(Process.clock_gettime(Process::CLOCK_MONOTONIC) - t_iter).round(2)}s"
    end

    def prepare_company_row(siren, _sheet) # rubocop:disable Metrics/MethodLength
      # Use preloaded data instead of querying
      siege_siret = @siege_establishments[siren]
      company_data = @company_data[siren] || {}

      # Get score entry for current list specifically (always a hash from single query)
      score_entry = @score_entries_by_company[siren]
      inpi_bce_ratio = @inpi_bce_ratios[siren] || {}

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
        format_sjcf(siren),
        format_delai_urssaf(siren),
        format_entreprise_recente(company_data[:creation]),
        format_tracking_status(siren),
        format_inpi_bce_ratio(inpi_bce_ratio[:taux_d_endettement]),
        format_inpi_bce_ratio(inpi_bce_ratio[:chiffre_d_affaires]),
        format_inpi_bce_ratio(inpi_bce_ratio[:resultat_net]),
        format_inpi_bce_ratio(inpi_bce_ratio[:ebit]),
        format_inpi_bce_ratio(inpi_bce_ratio[:ratio_de_liquidite])
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
      total = @social_debts[siren]
      return "-" unless total&.positive?

      total.round(2)
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
      when "plans"
        "Plans"
      when "ratios"
        "Ratios"
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

    def format_inpi_bce_ratio(value)
      return "-" if value.nil?

      rounded = value.to_f.round(2)
      rounded == rounded.truncate ? rounded.to_i : rounded
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
