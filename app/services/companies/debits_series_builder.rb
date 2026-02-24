module Companies
  class DebitsSeriesBuilder
    def initialize(start_date:, periodes:, debit_freshness_index:, forward_fill:, company: nil, siret_list: nil) # rubocop:disable Metrics/ParameterLists
      @company = company
      @siret_list = siret_list
      @start_date = start_date
      @periodes = periodes
      @debit_freshness_index = debit_freshness_index
      @forward_fill = forward_fill
    end

    def build
      debits_data = Companies::DebitsDataBuilder.forward_filled(
        company: @company,
        siret_list: @siret_list,
        start_date: @start_date,
        periodes: @periodes,
        forward_fill: @forward_fill,
        fill_until_index: @debit_freshness_index.call(@periodes)
      )

      parts_salariales = round_values(map_periodes_to_parts_salariales(debits_data))
      parts_patronales = round_values(map_periodes_to_parts_patronales(debits_data))

      {
        parts_salariales: clear_nil_series(parts_salariales),
        parts_patronales: clear_nil_series(parts_patronales)
      }
    end

    private

    def map_periodes_to_parts_salariales(debits_data)
      @periodes.map do |periode_str|
        periode_date = Date.parse(periode_str).beginning_of_month
        debit_record = debits_data[periode_date]
        debit_record && !debit_record[1].nil? ? debit_record[1].to_f : nil
      end
    end

    def map_periodes_to_parts_patronales(debits_data)
      @periodes.map do |periode_str|
        periode_date = Date.parse(periode_str).beginning_of_month
        debit_record = debits_data[periode_date]
        debit_record && !debit_record[2].nil? ? debit_record[2].to_f : nil
      end
    end

    def round_values(values)
      values.map { |value| value&.round }
    end

    def clear_nil_series(values)
      return [] if values.all?(&:nil?)

      values
    end
  end
end
