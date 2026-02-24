module Companies
  class FinancialDataBuilder
    def initialize(company)
      @company = company
    end

    def build
      return empty_payload if @company.siren.blank?

      service = Api::FinancialRatiosApiService.new(siren: @company.siren)
      api_response = service.fetch_financial_ratios

      if api_response && api_response["records"].present?
        records = api_response["records"].map { |r| r["record"]["fields"] }
        records.sort_by! { |r| r["date_cloture_exercice"] || "" }
        populate_data(records)
      else
        empty_payload
      end
    rescue StandardError => e
      empty_payload(error: e.message)
    end

    private

    def populate_data(records) # rubocop:disable Metrics/MethodLength
      dates = records.pluck("date_cloture_exercice").compact
      formatted_dates = dates.map { |d| Date.parse(d).strftime("%d/%m/%Y") }

      financial_fields = []
      datasets = {}
      dataset_names = {}

      allowed_fields.each do |field_key, field_label|
        next unless records.any? { |r| r.key?(field_key) }

        financial_fields << field_key
        datasets[field_key] = records.map { |r| r[field_key] }
        dataset_names[field_key] = field_label
      end

      financial_fields.sort!
      dataset_names_graph = dataset_names.except("ratio_de_liquidite", "taux_d_endettement")
      datasets_graph = datasets.except("ratio_de_liquidite", "taux_d_endettement")
      financial_fields_graph = financial_fields - %w[ratio_de_liquidite taux_d_endettement]

      {
        dates: dates,
        formatted_dates: formatted_dates,
        financial_fields: financial_fields,
        financial_fields_graph: financial_fields_graph,
        datasets: datasets,
        datasets_graph: datasets_graph,
        dataset_names: dataset_names,
        dataset_names_graph: dataset_names_graph,
        light_colors: colors,
        dark_colors: colors,
        error: nil
      }
    end

    def empty_payload(error: nil)
      {
        dates: [],
        formatted_dates: [],
        financial_fields: [],
        financial_fields_graph: [],
        datasets: {},
        datasets_graph: {},
        dataset_names: {},
        dataset_names_graph: {},
        light_colors: colors,
        dark_colors: colors,
        error: error
      }
    end

    def allowed_fields
      {
        "chiffre_d_affaires" => "Chiffre d'Affaires (€)",
        "ebit" => "Résultat d'exploitation (€)",
        "ebe" => "Excédent Brut d'exploitation (EBE) (€)",
        "resultat_net" => "Résultat net (€)",
        "marge_brute" => "Marge brute (€)",
        "taux_d_endettement" => "Taux d'endettement (%)",
        "ratio_de_liquidite" => "Ratio de liquidité (%)"
      }
    end

    def colors
      ["#6A6AF4", "#E1000F", "#B7A73F", "#E18B76", "#00A95F"]
    end
  end
end
