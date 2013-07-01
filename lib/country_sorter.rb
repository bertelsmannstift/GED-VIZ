module CountrySorter
  # sort_by
  #  data_type sum_in
  #  data_type sum_out
  #  data_type both
  #
  #  indicator_type
  #
  # find 5 biggest partners

  def self.sort_by_data_type(countries, year, type_with_unit, direction = :both)
    aggregator = DataAggregator.new
    countries.sort_by do |country|
      ids = country.country_ids
      case direction
      when :in
        aggregator.sum_in(ids, year, type_with_unit)
      when :out
        aggregator.sum_out(ids, year, type_with_unit)
      else
        sum_in  = aggregator.sum_in( ids, year, type_with_unit)
        sum_out = aggregator.sum_out(ids, year, type_with_unit)
        sum_in + sum_out
      end
    end.reverse
  end

  def self.sort_by_indicator_type(countries, year, indicator_type_with_unit)
    aggregator = IndicatorAggregator.new
    countries.sort_by do |country|
      aggregator.indicator_value(country.country_ids, year, indicator_type_with_unit, true)
    end.reverse
  end

  def biggest_partners(year, type_with_unit, direction = :out)
    aggregator = DataAggregator.new
    id = group_id

    iso3s_sorted = case direction
      when :in
        aggregator.incoming_top5(id, [], type_with_unit, year).keys
      when :out
        aggregator.outgoing_top5(id, [], type_with_unit, year).keys
      else
        aggregator.incoming_top5(id, [], type_with_unit, year).keys.zip(
          aggregator.outgoing_top5(id, [], type_with_unit, year).keys
        ).flatten.uniq[0...6]
      end

    iso3s_sorted.map { |iso3| Country.where(iso3: iso3) }.flatten
  end

end