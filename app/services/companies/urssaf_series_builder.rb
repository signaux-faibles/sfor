module Companies
  class UrssafSeriesBuilder
    def initialize(company:, start_date:, periodes:, debit_freshness_index:, forward_fill:)
      @company = company
      @start_date = start_date
      @periodes = periodes
      @debit_freshness_index = debit_freshness_index
      @forward_fill = forward_fill
    end

    def build
      build_payload(
        cotisations: build_cotisations,
        debits: build_debits,
        montant_echeancier: build_montant_echeancier
      )
    end

    private

    def build_payload(cotisations:, debits:, montant_echeancier:)
      {
        cotisations: cotisations,
        parts_salariales: debits[:parts_salariales],
        parts_patronales: debits[:parts_patronales],
        montant_echeancier: montant_echeancier
      }
    end

    def build_cotisations
      Companies::CotisationsSeriesBuilder.new(
        company: @company,
        start_date: @start_date,
        periodes: @periodes,
        forward_fill: @forward_fill
      ).build
    end

    def build_debits
      Companies::DebitsSeriesBuilder.new(
        company: @company,
        start_date: @start_date,
        periodes: @periodes,
        debit_freshness_index: @debit_freshness_index,
        forward_fill: @forward_fill
      ).build
    end

    def build_montant_echeancier
      Companies::DelaisSeriesBuilder.new(
        company: @company,
        start_date: @start_date,
        periodes: @periodes,
        forward_fill: @forward_fill
      ).build
    end
  end
end
