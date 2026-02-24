module Companies
  class EffectifApSeriesBuilder
    def initialize(company:, start_date:, periodes:)
      @company = company
      @start_date = start_date
      @periodes = periodes
    end

    def build
      effectifs_data = fetch_effectifs_data
      ap_data = fetch_ap_data

      effectifs = map_periodes_to_effectifs(effectifs_data)
      consommation_ap = map_periodes_to_consommation(ap_data)
      autorisation_ap = map_periodes_to_autorisation(ap_data)

      {
        effectifs: clear_nil_series(effectifs),
        consommation_ap: clear_nil_series(consommation_ap),
        autorisation_ap: clear_nil_series(autorisation_ap)
      }
    end

    private

    def fetch_effectifs_data
      OsfEntEffectif
        .where(siren: @company.siren)
        .where(periode: @start_date..)
        .order(:periode)
        .pluck(:periode, :effectif)
        .to_h
    end

    def fetch_ap_data
      ap_records = OsfAp
                   .where(siren: @company.siren)
                   .where(periode: @start_date..)
                   .order(:periode)
                   .pluck(:periode, :etp_consomme, :etp_autorise)

      Companies::ApDataBuilder.new(ap_records).aggregate
    end

    def map_periodes_to_effectifs(effectifs_data)
      @periodes.map do |periode_str|
        periode_date = Date.parse(periode_str)
        effectifs_data[periode_date]
      end
    end

    def map_periodes_to_consommation(ap_data)
      @periodes.map do |periode_str|
        periode_date = Date.parse(periode_str)
        ap_record = ap_data[periode_date]
        ap_record && ap_record[1] ? ap_record[1].round : nil
      end
    end

    def map_periodes_to_autorisation(ap_data)
      @periodes.map do |periode_str|
        periode_date = Date.parse(periode_str)
        ap_record = ap_data[periode_date]
        ap_record && ap_record[2] ? ap_record[2].round : nil
      end
    end

    def clear_nil_series(values)
      return [] if values.all?(&:nil?)

      values
    end
  end
end
