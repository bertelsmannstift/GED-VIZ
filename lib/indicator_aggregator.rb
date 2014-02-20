class IndicatorAggregator < Aggregator

  # Returns a hash with value, tendency, tendency_percent and missing
  def indicator_value(country_ids, year, type_with_unit, value_only = false)
    country_ids = country_ids.sort
    cached('indicator_value', country_ids, year, type_with_unit, value_only) do

      if country_ids.length == 1
        # Single country
        indicator_value_for_country(country_ids, year, type_with_unit, value_only)

      elsif country_ids.length > 1
        # Group of countries
        indicator_value_for_group(country_ids, year, type_with_unit, value_only)
      end

    end
  end

  # groups_as_ids := [ [group1_id1, group1_id2, ...], [group2_id1, group2_id2, ...], ...]
  def min_max_indicator_all(groups_as_ids, type_with_unit)
    cached('min_max_indicator_all', groups_as_ids, type_with_unit) do
      overall_min = 0
      overall_max = 0

      groups_as_ids.each do |country_ids|
        min, max = min_max_indicator_single(country_ids, type_with_unit)
        overall_min = min if overall_min > min
        overall_max = max if overall_max < max
      end

      [overall_min, overall_max]
    end
  end

  def calculate_percent_difference(unit, new_value, old_value)
    return nil if old_value.nil? || old_value == 0
    new_value = new_value
    old_value = old_value
    # Handle values that are already in percent
    if unit.is_proportional?
      new_value - old_value
    else
      new_value / old_value - 1
    end
  end

  def percent_to_tendency(unit, percent)
    return nil if percent.nil?
    percent_point = unit.is_proportional? ? percent : percent * 100
    #puts "percent_to_tendency unit #{unit.key} percent #{percent} percent_point #{percent_point}"
    if percent_point <= -9
      -2
    elsif percent_point <= -3
      -1
    elsif percent_point < 3
      0
    elsif percent_point < 9
      1
    else
      2
    end
  end

  # ---------------------------------------------------------------------------
  private

  # Returns a hash with value, tendency, tendency_percent and missing
  def indicator_value_for_country(country_ids, year, type_with_unit, value_only)
    #puts "indicator_value_for_country #{country_ids} #{year} #{type_with_unit}"
    indicator_value = IndicatorValue
      .select('value, tendency, tendency_percent, unit_id')
      .where(
        indicator_type_id: type_with_unit.type.id,
        unit_id:           type_with_unit.unit.id,
        country_id:        country_ids,
        year:              year
      )
      .first

    return missing_value(value_only) unless indicator_value

    value = indicator_value.value

    # Only return the value if requested
    return value if value_only

    tendency = indicator_value.tendency
    tendency_percent = indicator_value.tendency_percent

    {
      value: value,
      tendency: tendency,
      tendency_percent: tendency_percent,
      missing: false
    }
  end

  def indicator_value_for_group(country_ids, year, type_with_unit, value_only)
    #puts "indicator_value_for_group #{country_ids} #{year} #{type_with_unit}"

    is_addable_type = addable_type?(type_with_unit)
    unless is_addable_type
      return missing_value(value_only)
    end

    is_quotient_type = quotient_type?(type_with_unit)
    value = if is_quotient_type
      quotient_indicator_value(country_ids, year, type_with_unit)
    else
      sum_of_indicator_values(country_ids, year, type_with_unit)
    end

    # Return if any of the needed values was missing
    return missing_value(value_only) if value.nan?

    # Only return the value if requested
    return value if value_only

    # Calculate tendency
    last_year_value = if is_quotient_type
      quotient_indicator_value(country_ids, year - 1, type_with_unit)
    else
      sum_of_indicator_values(country_ids, year - 1, type_with_unit)
    end
    tendency, tendency_percent = calculate_tendency(
      type_with_unit,
      value,
      last_year_value
    )

    {
      value: value,
      tendency: tendency,
      tendency_percent: tendency_percent,
      missing: false
    }
  end

  def sum_of_indicator_values(country_ids, year, type_with_unit)
    #puts "sum_of_indicator_values #{country_ids} #{year} #{type_with_unit}"

    indicator_values = IndicatorValue.select('value, unit_id')
      .where(
        indicator_type_id: type_with_unit.type.id,
        unit_id:           type_with_unit.unit.id,
        country_id:        country_ids,
        year:              year
      )

    sum = indicator_values.reduce({ count: 0, value: 0.0 }) do |mem, iv|
      { count: mem[:count] + 1, value: mem[:value] + iv.value }
    end

    # Some values are missing
    return Float::NAN if sum[:count] < country_ids.length

    # All data is available, return the calculated value
    sum[:value]
  end

  def quotient_indicator_value(country_ids, year, type_with_unit)
    #puts "quotient_indicator_value #{country_ids} #{year} #{type_with_unit}"

    type_definition = quotient_type_definition(type_with_unit)
    dividend_twu = type_definition[:dividend]
    divisor_twu = type_definition[:divisor]

    # Get values
    dividend = sum_of_indicator_values(country_ids, year, dividend_twu)
    divisor = sum_of_indicator_values(country_ids, year, divisor_twu)

    # Conversion
    converter = type_definition[:converter]
    if converter.present?
      dividend, divisor = converter.call(dividend, divisor, dividend_twu, divisor_twu)
    end

    # Calculate quotient
    dividend / divisor
  end

  # Returns an array with tendency and tendency_percent
  def calculate_tendency(type_with_unit, value, last_value)
    last_value = 0.0 if last_value.nan?
    tendency_percent = calculate_percent_difference(
      type_with_unit.unit, value, last_value
    )
    tendency = percent_to_tendency(
      type_with_unit.unit, tendency_percent
    )
    [tendency, tendency_percent]
  end

  def missing_value(value_only)
    if value_only
      0.0
    else
      { value: nil, tendency: nil, tendency_percent: nil, missing: true }
    end
  end

  # Used for one country or country group
  def min_max_indicator_single(country_ids, type_with_unit)
    country_ids = country_ids.sort
    cached('min_max_indicator_single', country_ids, type_with_unit) do
      min = 0
      max = 0

      indicator_years.each do |year|
        value = indicator_value(country_ids, year, type_with_unit, true)
        min = value if min > value
        max = value if max < value
      end

      [min, max]
    end
  end

  def indicator_years
    cached('indicator_years') do
      IndicatorValue.uniq.pluck(:year)
    end
  end

  def quotient_type_definition(type_with_unit)
    IndicatorTypes.quotient_types.find do |type_definition|
      type_with_unit == type_definition[:twu]
    end
  end

  def quotient_type?(type_with_unit)
    quotient_type_definition(type_with_unit).present?
  end

  def addable_type?(type_with_unit)
    IndicatorTypes.addable_types.any? do |type_definition|
      type_with_unit == type_definition[:twu]
    end
  end

end