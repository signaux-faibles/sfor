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

    def initialize(list, companies, search_params, user)
      @list = list
      @companies = companies
      @search_params = search_params
      @user = user
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
        "SJCF",
        "Liste retraitée",
        "Délai de paiement Urssaf",
        "Entreprises récentes",
        "Accompagnement"
      ]
      sheet.add_row headers, style: Array.new(26) { header_style(sheet) }
    end

    def add_company_rows(sheet)
      # Preload associations to avoid N+1 queries
      companies_with_data = @companies.includes(
        :establishments,
        :company_score_entries,
        establishments: %i[department establishment_trackings]
      )

      companies_with_data.each do |company|
        sheet.add_row prepare_company_row(company, sheet),
                      style: Array.new(26, centered_style(sheet)),
                      types: [:string] * 26
      end
    end

    def prepare_company_row(company, _sheet) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
      siege_establishment = company.establishments.find_by(siege: true)
      score_entry = company.company_score_entries.find_by(list_name: @list.label)

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
        format_liste_retraitee(company.siren),
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
      current_date = Date.current
      sql = ActiveRecord::Base.sanitize_sql([
                                              "SELECT libelle_procol FROM procol_at_date(?) AS procol WHERE procol.siren = ?", # rubocop:disable Layout/LineLength
                                              current_date, siren
                                            ])
      result = ActiveRecord::Base.connection.execute(sql).first
      result ? result["libelle_procol"] : "In Bonis"
    rescue StandardError
      "-"
    end

    def format_last_effectif(siren)
      latest = OsfEntEffectif.where(siren: siren).order(periode: :desc).first
      latest&.effectif&.to_i || "-"
    end

    def format_social_debt(_siren, siege_establishment)
      return "-" unless siege_establishment

      debit = OsfDebit.where(siret: siege_establishment.siret, is_last: true).first
      return "-" unless debit

      total = (debit.part_ouvriere.to_f + debit.part_patronale.to_f)
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
      # Check if company appears in the current list
      current_entry_exists = CompanyScoreEntry.exists?(siren: siren, list_name: @list.label)
      return "-" unless current_entry_exists

      # Check if company appears in other lists
      other_entries_exist = CompanyScoreEntry.where(siren: siren)
                                             .where.not(list_name: @list.label)
                                             .exists?

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
      SjcfCompany.exists?(siren: siren, libelle_liste: @list.label) ? "Oui" : "Non"
    end

    def format_liste_retraitee(siren)
      # Check if company appears in previous lists (retraitée means it was in a previous list)
      other_entries = CompanyScoreEntry.where(siren: siren)
                                       .where.not(list_name: @list.label)
                                       .exists?
      other_entries ? "Oui" : "Non"
    end

    def format_delai_urssaf(siege_establishment)
      return "-" unless siege_establishment

      has_delai = OsfDelai.active_dette_urssaf?(siege_establishment.siret)
      has_delai ? "Oui" : "Non"
    end

    def format_entreprise_recente(creation_date)
      return "-" unless creation_date

      three_years_ago = Date.current - 3.years
      creation_date >= three_years_ago ? "Oui" : "Non"
    end

    def format_tracking_status(siren) # rubocop:disable Metrics/MethodLength
      # Check if any establishment of this company has tracking
      establishments = Establishment.where(siren: siren)
      trackings = EstablishmentTracking
                  .where(establishment_siret: establishments.pluck(:siret))
                  .kept

      return "Pas d'accompagnement" if trackings.empty?

      in_progress = trackings.in_progress.exists?
      return "Accompagnement en cours" if in_progress

      under_surveillance = trackings.under_surveillance.exists?
      return "Accompagnement sous surveillance" if under_surveillance

      completed = trackings.completed.exists?
      return "Accompagnement terminé" if completed

      "Pas d'accompagnement"
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
