module Companies
  class DelaisSeriesBuilder
    def initialize(start_date:, periodes:, forward_fill:, fill_until_index: nil, company: nil, siret_list: nil) # rubocop:disable Metrics/ParameterLists
      @company = company
      @siret_list = siret_list
      @start_date = start_date
      @periodes = periodes
      @forward_fill = forward_fill
      @fill_until_index = fill_until_index
    end

    def build
      delais = fetch_delais_data
      values = map_periodes_to_montant_echeancier(delais)
      values = @forward_fill.call(values, fill_until_index: @fill_until_index)
      values = apply_freshness_limit(values, @fill_until_index)
      clear_nil_series(round_values(values))
    end

    private

    def fetch_delais_data
      siret_list = @siret_list || @company&.establishments&.pluck(:siret) || []
      return [] if siret_list.empty?

      end_date = Date.current.end_of_month
      OsfDelai
        .where(siret: siret_list)
        .where("date_creation <= ? AND date_echeance >= ?", end_date, @start_date)
        .where.not(montant_echeancier: nil)
        .where.not(date_creation: nil)
        .where.not(date_echeance: nil)
        .order(:date_creation)
    end

    def map_periodes_to_montant_echeancier(delais)
      @periodes.map do |periode_str|
        most_recent_delai_montant(periode_str, delais)
      end
    end

    def most_recent_delai_montant(periode_str, delais)
      periode_date = Date.parse(periode_str).beginning_of_month
      active_delais = active_delais_for_periode(periode_date, delais)
      unique_delais = unique_delais_by_range(active_delais)
      unique_delais.max_by(&:date_creation)&.montant_echeancier&.to_f
    end

    def active_delais_for_periode(periode_date, delais)
      delais.select do |delai|
        delai.date_creation.beginning_of_month <= periode_date && periode_date <= delai.date_echeance
      end
    end

    def unique_delais_by_range(delais)
      delais.uniq { |delai| [delai.date_creation, delai.date_echeance] }
    end

    def round_values(values)
      values.map { |value| value&.round }
    end

    def clear_nil_series(values)
      return [] if values.all?(&:nil?)

      values
    end

    def apply_freshness_limit(values, fill_until_index)
      return values if fill_until_index.nil?

      values.map.with_index do |value, index|
        index <= fill_until_index ? value : nil
      end
    end
  end
end
