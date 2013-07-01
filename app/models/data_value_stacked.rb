class DataValueStacked < ActiveRecord::Base

  # Stacked outgoing values with running sum, keeps attention to country groups
  # FLAG: other_top5 - Gets other Top 5 outgoing relations
  def self.outgoing_stacked(id, other_ids, type_with_unit, year, other_top5 = false)
    id = Aggregator.normalize_id(id)
    ids = id.split('-')
    other_ids = Aggregator.normalize_ids(other_ids)
    Aggregator.check_type_with_unit(type_with_unit)
    year = Aggregator.normalize_year(year)

    other_group_ids = other_ids.reduce([]) do |memo, id|
      memo << id if id.include?('-')
      memo
    end

    all_ids = ids + other_group_ids

    ids_for_sql = ids.join(', ')
    all_ids_for_sql = Aggregator.ids_for_sql(all_ids)
    other_ids_for_sql = Aggregator.ids_for_sql(other_ids)

    type_id = type_with_unit.type.id
    unit_id = type_with_unit.unit.id

    # Calculate values for groups
    subqueries = other_group_ids.map do |group_other_id|
      group_ids_for_sql = Aggregator.group_ids_for_sql(group_other_id)
      "
      SELECT '#{id}' as `country_from_id`, '#{group_other_id}' as `country_to_id`, SUM(`value`) as `value`
      FROM
        `data_values`
      WHERE
        `country_from_id` IN ( #{ids_for_sql} ) AND
        `country_to_id` IN ( #{group_ids_for_sql} ) AND
        `year` = #{year} AND
        `data_type_id` = #{type_id} AND `unit_id` = #{unit_id}
      "
    end.join(" UNION ")

    subqueries += " UNION " unless subqueries.empty?

    # Calculate values for remaining countries
    subqueries += "
      SELECT '#{id}' as `country_from_id`, `country_to_id`, SUM(`value`) as `value`
      FROM
        `data_values`
      WHERE
        `country_from_id` IN ( #{ids_for_sql} ) AND
        `country_to_id` NOT IN ( #{all_ids_for_sql} ) AND
        `year` = #{year} AND
        `data_type_id` = #{type_id} AND `unit_id` = #{unit_id}
      GROUP BY `country_to_id`
    "

    # Calculate running sum and limit result
    query = "
      SELECT `country_from_id`, `country_to_id`, `value`, `running_sum` FROM (
      SELECT `country_from_id`, `country_to_id`, `value`, @running_sum:=@running_sum+`value` as running_sum
      FROM (SELECT @running_sum := 0) s, (
        #{subqueries}
        ORDER BY `value` ASC
      ) calculation WHERE `value` IS NOT NULL
      ) wrapper"

    if other_top5
      query += "
        #{"WHERE `country_to_id` NOT IN ( #{all_ids_for_sql} )" unless other_ids.empty?}
        ORDER BY `running_sum` DESC LIMIT 5
      "
    else
      query += "
        #{"WHERE `country_to_id` IN ( #{other_ids_for_sql} )" unless other_ids.empty?}
      "
    end

    results = self.connection.execute(sanitize_sql(query))
    results.map do |hash|
      {
        group_from: hash[0],
        group_to: hash[1],
        # Convert BigDecimal to Float
        value: hash[2].to_f,
        running_sum: hash[3].to_f
      }
    end
  end

  # Stacked incoming values with running sum, keeps attention to country groups
  # FLAG: other_top5 - Gets other Top 5 incoming relations
  def self.incoming_stacked(id, other_ids, type_with_unit, year, other_top5 = false)
    id = Aggregator.normalize_id(id)
    ids = id.split('-')
    other_ids = Aggregator.normalize_ids(other_ids)
    Aggregator.check_type_with_unit(type_with_unit)
    year = Aggregator.normalize_year(year)

    other_group_ids = other_ids.reduce([]) do |memo, id|
      memo << id if id.include?('-')
      memo
    end

    all_ids = ids + other_group_ids

    ids_for_sql = ids.join(', ')
    all_ids_for_sql = Aggregator.ids_for_sql(all_ids)
    other_ids_for_sql = Aggregator.ids_for_sql(other_ids)

    type_id = type_with_unit.type.id
    unit_id = type_with_unit.unit.id

    # Calculate values for groups
    subqueries = other_group_ids.map do |other_id|
      group_ids_for_sql = Aggregator.group_ids_for_sql(other_id)
      "
      SELECT '#{id}' as `country_to_id`, '#{other_id}' as `country_from_id`, SUM(`value`) as `value`
      FROM
        `data_values`
      WHERE
        `country_to_id` IN ( #{ids_for_sql} ) AND
        `country_from_id` IN ( #{group_ids_for_sql} ) AND
        `year` = #{year} AND
        `data_type_id` = #{type_id} AND `unit_id` = #{unit_id}
      "
    end.join(" UNION ")

    subqueries += " UNION " unless subqueries.empty?

    # Calculate values for remaining countries
    subqueries += "
      SELECT '#{id}' as `country_to_id`, `country_from_id`, SUM(`value`) as `value`
      FROM
        `data_values`
      WHERE
        `country_to_id` IN ( #{ids_for_sql} ) AND
        `country_from_id` NOT IN ( #{all_ids_for_sql} ) AND
        `year` = #{year} AND
        `data_type_id` = #{type_id} AND `unit_id` = #{unit_id}
      GROUP BY `country_from_id`
    "

    # Calculate running sum and limit result
    query = "
      SELECT `country_to_id`, `country_from_id`, `value`, `running_sum` FROM (
      SELECT `country_to_id`, `country_from_id`, `value`, @running_sum:=@running_sum+`value` as running_sum
      FROM (SELECT @running_sum := 0) s, (
        #{subqueries}
        ORDER BY `value` ASC
      ) calculation WHERE `value` IS NOT NULL
      ) wrapper
    "

    if other_top5
      query += "
        #{"WHERE `country_from_id` NOT IN ( #{all_ids_for_sql} )" unless other_ids.empty?}
        ORDER BY `running_sum` DESC LIMIT 5
      "
    else
      query += "
        #{"WHERE `country_from_id` IN ( #{other_ids_for_sql} )" unless other_ids.empty?}
      "
    end

    results = self.connection.execute(sanitize_sql(query))
    results.map do |hash|
      {
        group_to: hash[0],
        group_from: hash[1],
        # Convert BigDecimal to Float
        value: hash[2].to_f,
        running_sum: hash[3].to_f
      }
    end
  end

end