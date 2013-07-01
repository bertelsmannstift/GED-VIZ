class IndicatorAggregator < Aggregator

  # Returns a hash with value, tendency, tendency_percebt and missing
  def indicator_value(country_ids, year, type_with_unit, value_only = false)
    cached('indicator_value', country_ids, year, type_with_unit, value_only) do

      # Single country
      if country_ids.length == 1
        indicator_value_for_country(
          country_ids, year, type_with_unit, value_only
        )

        # Group
      elsif country_ids.length > 1
        indicator_value_for_group(
          country_ids, year, type_with_unit, value_only
        )
      end

    end
  end

  def quotient_indicator_value(country_ids, year, fraction)
    dividend, divisor = fraction.map do |type_with_unit|
      sum_of_indicator_values(country_ids, year, type_with_unit)
    end
    (dividend.to_f / divisor.to_f) * 100
  end

  # groups_as_ids := [ [group1_id1, group1_id2, ...], [group2_id1, group2_id2, ...], ...]
  def min_max_indicator_all(groups_as_ids, type_with_unit)
    cached('min_max_indicator_all', groups_as_ids, type_with_unit) do
      overall_min = 0; overall_max = 0

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
    new_value = new_value.to_f
    old_value = old_value.to_f
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

  private

  def indicator_value_for_country(country_ids, year, type_with_unit, value_only)
    indicator_value = IndicatorValue.select('value, tendency, tendency_percent, unit_id')
    .where(
      indicator_type_id: type_with_unit.type.id,
      unit_id:           type_with_unit.unit.id,
      country_id:        country_ids,
      year:              year
    ).first

    return missing_value(value_only) unless indicator_value

    value = indicator_value.value.to_f

    # Return value if method is used to calculate the value only
    return value if value_only

    tendency = indicator_value.tendency
    tendency_percent = indicator_value.tendency_percent.to_f

    {
      value: value,
      tendency: tendency,
      tendency_percent: tendency_percent,
      missing: false
    }
  end

  def indicator_value_for_group(country_ids, year, type_with_unit, value_only)
    is_quotient_type = IndicatorTypes.quotient_types.include? type_with_unit
    if is_quotient_type
      quotient_indicator_value_for_group(country_ids, year, type_with_unit, value_only)
    else
      # Add up precalculated values
      value = sum_of_indicator_values(country_ids, year, type_with_unit)

      # Return if any of the needed values was missing
      return missing_value(value_only) if value.nan?

      # Return value if method is used to calculate the value only
      return value if value_only

      # Calculate tendency
      tendency, tendency_percent = calculate_tendency(
        type_with_unit,
        value,
        sum_of_indicator_values(country_ids, year - 1, type_with_unit)
      )

      {
        value: value,
        tendency: tendency,
        tendency_percent: tendency_percent,
        missing: false
      }
    end
  end

  def quotient_indicator_value_for_group(country_ids, year, type_with_unit, value_only)
    # Calculate derived value by type
    fraction = IndicatorTypes.quotient_types[type_with_unit]
    value = quotient_indicator_value(country_ids, year, fraction)

    # Return if any of the needed values was missing
    return missing_value(value_only) if value.nan?

    return value if value_only

    # Calculate tendency
    tendency, tendency_percent = calculate_tendency(
      type_with_unit,
      value,
      quotient_indicator_value(country_ids, year - 1, fraction)
    )

    {
      value: value,
      tendency: tendency,
      tendency_percent: tendency_percent,
      missing: false
    }
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
      0
    else
      { value: nil, tendency: nil, tendency_percent: nil, missing: true }
    end
  end

  # Used for one country or country group
  def min_max_indicator_single(country_ids, type_with_unit)
    cached('min_max_indicator_single', country_ids, type_with_unit) do
      min = 0; max = 0
      indicator_years.each do |year|
        value = indicator_value(country_ids, year, type_with_unit, true)
        min = value if min > value
        max = value if max < value
      end

      [min, max]
    end
  end

  def sum_of_indicator_values(country_ids, year, type_with_unit)
    indicator_values = IndicatorValue.select('value, unit_id').where(
      indicator_type_id: type_with_unit.type.id,
      unit_id:           type_with_unit.unit.id,
      country_id:        country_ids,
      year:              year
    )
    sum = indicator_values.reduce({ count: 0, value: 0 }) do |mem, iv|
      { count: mem[:count] + 1, value: mem[:value] + iv.value }
    end

    # Some values are missing
    return Float::NAN if sum[:count] < country_ids.length

    # All data was available, return the calculated value
    sum[:value].to_f
  end

  def indicator_years
    cached('indicator_years') do
      IndicatorValue.uniq.pluck(:year)
    end
  end

end