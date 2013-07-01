class CurrencyConverter
  class << self
    def convert(unit, year, value)
      CURRENCY_RULES['conversions'].each do |rule|
        unit_index = nil

        rule['from'].each_with_index do |from_unit, index|
          break unit_index = index if from_unit == unit
        end

        if unit_index
          unit_to = rule['to'][unit_index]
          factor = rule['years'][year.to_i]

          yield [(value.to_f * factor), unit_to]
        end
      end

      nil
    end

    def other_unit(unit)
      CURRENCY_RULES['conversions'].each do |rule|
        unit_index = nil

        rule['from'].each_with_index do |from_unit, index|
          break unit_index = index if from_unit == unit
        end

        if unit_index
          unit_to = rule['to'][unit_index]

          yield unit_to
        end
      end

      nil
    end
  end
end