module Companies
  class ApDataBuilder
    def initialize(records)
      @records = records
    end

    def aggregate
      @records.each_with_object({}) do |(periode, etp_consomme, etp_autorise), ap_data|
        existing = ap_data[periode]
        ap_data[periode] = aggregate_record(existing, periode, etp_consomme, etp_autorise)
      end
    end

    private

    def aggregate_record(existing_record, periode, etp_consomme, etp_autorise)
      return [periode, etp_consomme || 0, etp_autorise || 0] unless existing_record

      [
        periode,
        (existing_record[1] || 0) + (etp_consomme || 0),
        (existing_record[2] || 0) + (etp_autorise || 0)
      ]
    end
  end
end
