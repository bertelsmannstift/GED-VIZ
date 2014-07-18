class DataAggregator < Aggregator

  # Outgoing volume as a sum of all relations,
  # even if the target countries are not currently selected
  def sum_out(country_ids, year, type_with_unit)
    cached('sum_out', country_ids, year, type_with_unit) do
      DataValue.where(
        data_type_id:    type_with_unit.type.id,
        unit_id:         type_with_unit.unit.id,
        year:            year,
        country_from_id: country_ids
      )
      .where('country_to_id NOT IN (?)', country_ids)
      .sum(:value)
    end
  end

  # Incoming volume as a sum of all relations,
  # even if the source countries are not currently selected
  def sum_in(country_ids, year, type_with_unit)
    country_ids = country_ids.sort
    cached('sum_in', country_ids, year, type_with_unit) do
      DataValue.where(
        data_type_id:    type_with_unit.type.id,
        unit_id:         type_with_unit.unit.id,
        year:            year,
        country_to_id:   country_ids,
      )
      .where('country_from_id NOT IN (?)', country_ids)
      .sum(:value)
    end
  end

  # Calculates sum for given groups and data_type for all years
  # Adds highest single value in whole timespan
  # groups_as_ids := [ [group1_id1, group1_id2, ...], [group2_id1, group2_id2, ...], ...]
  def sum_yearly_for_groups(groups_as_ids, type_with_unit)
    cached('sum_yearly_for_groups', groups_as_ids, type_with_unit) do
      YearSum.yearly_for_groups(groups_as_ids, type_with_unit)
    end
  end

  # Calculates outgoing relations and their position with other existing groups in mind
  def stacked_outgoing(id, other_ids, type_with_unit, year)
    other_ids.sort!
    cached('stacked_outgoing', id, other_ids, type_with_unit, year) do
      values = DataValueStacked.outgoing_stacked(id, other_ids, type_with_unit, year)
      values.reduce({}) do |memo, stacked|
        memo[iso3_by_group_id(stacked[:group_to])] = {
          value: stacked[:value],
          stacked_amount_from: stacked[:running_sum] - stacked[:value]
        }
        memo
      end
    end
  end

  # Calculates incoming relations and their position with other existing groups in mind
  def stacked_incoming(id, other_ids, type_with_unit, year)
    other_ids.sort!
    cached('stacked_incoming', id, other_ids, type_with_unit, year) do
      values = DataValueStacked.incoming_stacked(id, other_ids, type_with_unit, year)
      values.reduce([]) do |memo, stacked|
        memo << {
          from_group_id: stacked[:group_from],
          to_group_iso3: iso3_by_group_id(stacked[:group_to]),
          value: stacked[:value],
          stacked_amount_to: stacked[:running_sum] - stacked[:value]
        }
        memo
      end
    end
  end

  # Calculates the five biggest outgoing relations
  # This method has to pay attention to other country groups,
  # so the positioning of the sparklines is correct
  def outgoing_top5(id, other_ids, type_with_unit, year)
    other_ids.sort!
    cached('outgoing_top5', id, other_ids, type_with_unit, year) do
      values = DataValueStacked.outgoing_stacked(id, other_ids, type_with_unit, year, 'TOP 5')
      values.reduce({}) do |memo, stacked|
        memo[iso3_by_group_id(stacked[:group_to])] = {
          value: stacked[:value],
          stacked_amount_from: stacked[:running_sum] - stacked[:value]
        }
        memo
      end
    end
  end

  # Calculates the five biggest incoming relations
  # This method has to pay attention to other country groups,
  # so the positioning of the sparklines is correct
  def incoming_top5(id, other_ids, type_with_unit, year)
    other_ids.sort!
    cached('incoming_top5', id, other_ids, type_with_unit, year) do
      values = DataValueStacked.incoming_stacked(id, other_ids, type_with_unit, year, 'TOP 5')
      values.reduce({}) do |memo, stacked|
        memo[iso3_by_group_id(stacked[:group_from])] = {
          value: stacked[:value],
          stacked_amount_to: stacked[:running_sum] - stacked[:value]
        }
        memo
      end
    end
  end

  # Returns all missing relation data points between the given country ids
  # as an array of hashes:
  # { country_from_id, country_from_iso3, country_to_id, country_to_iso3}
  def missing_relations_for_countries(ids, type_with_unit, year)
    cached('missing_relations', ids, type_with_unit, year) do
      MissingData.missing_relations(ids, type_with_unit, year)
    end
  end

  # Returns all country ids without a single relation given a direction, type and year
  # as an array of { country_id, iso3, direction: 'data_from|data_to' }
  def countries_without_relations(ids, type_with_unit, year)
    cached('without_relations', ids, type_with_unit, year) do
      MissingData.without_relations(ids, type_with_unit, year)
    end
  end

  # Returns an array with all years in the database.
  def all_years
    DataValue.uniq.pluck(:year)
  end

  private

  # Returns iso3 values for countries and country groups
  def iso3_by_group_id(group_id)
    if group_id.is_a?(Integer)
      return Country.where(id: group_id).pluck(:iso3).first
    end

    cached('iso3_by_group_id', group_id) do
      group_id.split('-').map do |id|
        Country.where(id: id).pluck(:iso3).first
      end.sort.join('-')
    end
  end

end