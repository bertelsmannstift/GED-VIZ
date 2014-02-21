class CurrencyConverter

  def self.convert(unit, year, value)
    CURRENCY_RULES['conversions'].each do |rule|
      unit_index = rule['from'].find_index do |from_unit|
        from_unit == unit
      end

      if unit_index
        unit_to = rule['to'][unit_index]
        factor = rule['years'][year.to_i]

        yield [(value.to_f * factor), unit_to]
      end
    end

    nil
  end

  # Returns the first matching target currency unit
  def self.other_unit(unit)
    CURRENCY_RULES['conversions'].each do |rule|
      unit_index = rule['from'].find_index do |from_unit|
        from_unit == unit
      end

      if unit_index
        return rule['to'][unit_index]
      end
    end
    nil
  end

end