class YearSum < ActiveRecord::Base

  # Calculates sum for given groups and data_type for all years
  # Adds highest single value in whole timespan
  #
  # groups_as_ids := [ [group1_id1, group1_id2, ...], [group2_id1, group2_id2, ...], ...]
  def self.yearly_for_groups(groups_as_ids, type_with_unit)
    type_id = type_with_unit.type.id
    unit_id = type_with_unit.unit.id

    # Generate sub queries for each group
    subqueries = groups_as_ids.map do |country_ids|
      country_ids = Aggregator.normalize_ids(country_ids)
      country_ids_for_sql = country_ids.join(',')
      "
      SELECT year, SUM(`value`) as sum FROM
      `data_values`
      WHERE
        (
          (`country_from_id` IN ( #{country_ids_for_sql} ) AND `country_to_id` NOT IN ( #{country_ids_for_sql} ))
            OR
          (`country_to_id` IN ( #{country_ids_for_sql} ) AND `country_from_id` NOT IN ( #{country_ids_for_sql} ))
        ) AND
        `data_type_id` = #{type_id} AND
        `unit_id` = #{unit_id}
      GROUP BY `year`
      "
    end.join(" UNION ")

    # Calculate yearly sum and maximum value
    query = "
      SELECT year, SUM(`sum`) AS overall, MAX(`sum`) as max FROM
      (
      #{subqueries}
      ) wrapper
      GROUP BY `year`
    "

    yearly_totals = Hash.new
    max_overall = 0.0

    results = self.connection.execute(sanitize_sql(query))
    results.each do |year, sum, max|
      # Convert BigDecimal to Float
      sum = sum.to_f
      max = max.to_f
      yearly_totals[year] = sum
      max_overall = max if max > max_overall
    end

    [yearly_totals, max_overall]
  end

end