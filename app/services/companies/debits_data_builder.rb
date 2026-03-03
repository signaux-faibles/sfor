module Companies
  class DebitsDataBuilder
    def self.aggregate_records(debits)
      debits.each_with_object({}) do |(periode, part_ouvriere, part_patronale), debits_data|
        periode_normalized = periode.to_date.beginning_of_month
        part_ouvriere_val = part_ouvriere ? part_ouvriere.to_f : 0.0
        part_patronale_val = part_patronale ? part_patronale.to_f : 0.0
        existing = debits_data[periode_normalized]

        debits_data[periode_normalized] = if existing
                                            [
                                              periode_normalized,
                                              existing[1].to_f + part_ouvriere_val,
                                              existing[2].to_f + part_patronale_val
                                            ]
                                          else
                                            [periode_normalized, part_ouvriere_val, part_patronale_val]
                                          end
      end
    end

    def self.forward_filled(start_date:, periodes:, forward_fill:, company: nil, siret_list: nil, fill_until_index: nil) # rubocop:disable Metrics/ParameterLists
      siret_list ||= company&.establishments&.pluck(:siret) || []
      return {} if siret_list.empty?

      establishments_data = build_establishments_debits_data(
        siret_list,
        start_date,
        periodes,
        fill_until_index,
        forward_fill
      )

      aggregate_forward_filled_debits(establishments_data, periodes)
    end

    def self.build_establishments_debits_data(siret_list, start_date, periodes, fill_until_index, forward_fill)
      siret_list.each_with_object({}) do |siret, establishments_data|
        debits = OsfDebit
                 .where(siret: siret)
                 .where(periode: start_date..)
                 .order(:periode)
                 .pluck(:periode, :part_ouvriere, :part_patronale)

        debits_hash = build_debits_hash(debits)
        parts_sal = map_debit_parts(periodes, debits_hash, 1)
        parts_pat = map_debit_parts(periodes, debits_hash, 2)

        establishments_data[siret] = {
          parts_salariales: forward_fill.call(parts_sal, fill_to_end: true, fill_until_index: fill_until_index),
          parts_patronales: forward_fill.call(parts_pat, fill_to_end: true, fill_until_index: fill_until_index)
        }
      end
    end

    def self.build_debits_hash(debits)
      debits.each_with_object({}) do |(periode, part_ouvriere, part_patronale), debits_hash|
        periode_normalized = periode.to_date.beginning_of_month
        debits_hash[periode_normalized] = [
          periode_normalized,
          part_ouvriere ? part_ouvriere.to_f : nil,
          part_patronale ? part_patronale.to_f : nil
        ]
      end
    end

    def self.map_debit_parts(periodes, debits_hash, part_index)
      periodes.map do |periode_str|
        periode_date = Date.parse(periode_str).beginning_of_month
        debit_record = debits_hash[periode_date]
        debit_record && !debit_record[part_index].nil? ? debit_record[part_index].to_f : nil
      end
    end

    def self.aggregate_forward_filled_debits(establishments_data, periodes)
      periodes.each_with_index.with_object({}) do |(periode_str, index), debits_data|
        periode_date = Date.parse(periode_str).beginning_of_month
        parts_salariales_values = establishments_data.values.map { |data| data[:parts_salariales][index] }
        parts_patronales_values = establishments_data.values.map { |data| data[:parts_patronales][index] }

        part_sal_sum = if parts_salariales_values.all?(&:nil?)
                         nil
                       else
                         parts_salariales_values.compact.sum
                       end
        part_pat_sum = if parts_patronales_values.all?(&:nil?)
                         nil
                       else
                         parts_patronales_values.compact.sum
                       end

        debits_data[periode_date] = [periode_date, part_sal_sum, part_pat_sum]
      end
    end
  end
end
