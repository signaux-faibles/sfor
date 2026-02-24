module Companies
  class CotisationsSeriesBuilder
    def initialize(start_date:, periodes:, forward_fill:, company: nil, siret_list: nil)
      @company = company
      @siret_list = siret_list
      @start_date = start_date
      @periodes = periodes
      @forward_fill = forward_fill
    end

    def build
      cotisations_data = fetch_cotisations_data
      values = map_periodes_to_cotisations(cotisations_data)
      values = @forward_fill.call(values)
      clear_nil_series(round_values(values))
    end

    private

    def fetch_cotisations_data
      siret_list = @siret_list || @company&.establishments&.pluck(:siret) || []
      return {} if siret_list.empty?

      cotisations = OsfCotisation
                    .where(siret: siret_list)
                    .where(periode: @start_date..)
                    .order(:periode)
                    .pluck(:periode, :du)

      cotisations.each_with_object({}) do |(periode, du), cotisations_data|
        periode_normalized = periode.beginning_of_month
        cotisations_data[periode_normalized] = (cotisations_data[periode_normalized] || 0) + (du || 0)
      end
    end

    def map_periodes_to_cotisations(cotisations_data)
      @periodes.map do |periode_str|
        periode_date = Date.parse(periode_str)
        cotisations_data[periode_date]&.to_f
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
