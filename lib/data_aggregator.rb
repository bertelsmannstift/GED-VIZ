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
      .to_f
    end
  end

  # Incoming volume as a sum of all relations,
  # even if the source countries are not currently selected
  def sum_in(country_ids, year, type_with_unit)
    country_ids.sort!
    cached('sum_in', country_ids, year, type_with_unit) do
      DataValue.where(
        data_type_id:    type_with_unit.type.id,
        unit_id:         type_with_unit.unit.id,
        year:            year,
        country_to_id:   country_ids,
      )
      .where('country_from_id NOT IN (?)', country_ids)
      .sum(:value)
      .to_f
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
  # This method has to pay attention to other country groups, so the positioning of the sparklines is correct
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
  # This method has to pay attention to other country groups, so the positioning of the sparklines is correct
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

  def missing_relations_for_countries(all_ids, type_with_unit, year)
    cached('missing_relations', all_ids, type_with_unit, year) do
      MissingData.missing_relations(all_ids, type_with_unit, year)
    end
  end

  def countries_without_relations(all_ids, type_with_unit, year)
    cached('without_relations', all_ids, type_with_unit, year) do
      MissingData.without_relations(all_ids, type_with_unit, year)
    end
  end

  private

  def value(country_from_ids, country_to_ids, year, type_with_unit)
    cached('value', country_from_ids, country_to_ids, year, type_with_unit) do
      DataValue.where(
        data_type_id:    type_with_unit.type.id,
        unit_id:         type_with_unit.unit.id,
        year: year,
        country_from_id: country_from_ids,
        country_to_id:   country_to_ids
      )
      .sum(:value)
      .to_f
    end
  end

  # Returns iso3 values for countries and country groups
  def iso3_by_group_id(group_id)
    return Country.where(id: group_id).pluck(:iso3).first if group_id.is_a?(Fixnum)

    cached('iso3_by_group_id', group_id) do
      group_id.split('-').map do |id|
        Country.where(id: id).pluck(:iso3).first
      end.sort.join('-')
    end
  end

end