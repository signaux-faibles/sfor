module Establishments
  class EffectifApSeriesBuilder
    def initialize(establishment:, start_date:, periodes:, effectif_freshness_index: nil, ap_freshness_index: nil)
      @establishment = establishment
      @start_date = start_date
      @periodes = periodes
      @effectif_freshness_index = effectif_freshness_index
      @ap_freshness_index = ap_freshness_index
    end

    def build
      effectifs_data = fetch_effectifs_data
      ap_data = fetch_ap_data

      effectifs = apply_freshness_limit(map_periodes_to_effectifs(effectifs_data), @effectif_freshness_index)
      consommation_ap = apply_freshness_limit(map_periodes_to_consommation(ap_data), @ap_freshness_index)
      autorisation_ap = apply_freshness_limit(map_periodes_to_autorisation(ap_data), @ap_freshness_index)

      {
        effectifs: clear_nil_series(effectifs),
        consommation_ap: clear_nil_series(consommation_ap),
        autorisation_ap: clear_nil_series(autorisation_ap)
      }
    end

    private

    def fetch_effectifs_data
      OsfEffectif
        .where(siret: @establishment.siret)
        .where(periode: @start_date..)
        .order(:periode)
        .pluck(:periode, :effectif)
        .to_h
    end

    def fetch_ap_data
      ap_records = OsfAp
                   .where(siret: @establishment.siret)
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

    def apply_freshness_limit(values, fill_until_index)
      return values if fill_until_index.nil?

      values.map.with_index do |value, index|
        index <= fill_until_index ? value : nil
      end
    end
  end
end
