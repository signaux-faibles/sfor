module Establishments
  class UrssafSeriesBuilder
    def initialize(establishment:, start_date:, periodes:, debit_freshness_index:, cotisation_freshness_index:, # rubocop:disable Metrics/ParameterLists
                   delai_freshness_index:, forward_fill:)
      @establishment = establishment
      @start_date = start_date
      @periodes = periodes
      @debit_freshness_index = debit_freshness_index
      @cotisation_freshness_index = cotisation_freshness_index
      @delai_freshness_index = delai_freshness_index
      @forward_fill = forward_fill
    end

    def build
      {
        cotisations: build_cotisations,
        parts_salariales: build_debits[:parts_salariales],
        parts_patronales: build_debits[:parts_patronales],
        montant_echeancier: build_montant_echeancier
      }
    end

    private

    def siret_list
      [@establishment.siret].compact
    end

    def build_cotisations
      Companies::CotisationsSeriesBuilder.new(
        siret_list: siret_list,
        start_date: @start_date,
        periodes: @periodes,
        forward_fill: @forward_fill,
        fill_until_index: @cotisation_freshness_index
      ).build
    end

    def build_debits
      Companies::DebitsSeriesBuilder.new(
        siret_list: siret_list,
        start_date: @start_date,
        periodes: @periodes,
        debit_freshness_index: @debit_freshness_index,
        forward_fill: @forward_fill
      ).build
    end

    def build_montant_echeancier
      Companies::DelaisSeriesBuilder.new(
        siret_list: siret_list,
        start_date: @start_date,
        periodes: @periodes,
        forward_fill: @forward_fill,
        fill_until_index: @delai_freshness_index
      ).build
    end
  end
end
