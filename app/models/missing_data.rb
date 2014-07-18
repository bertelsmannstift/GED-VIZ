class MissingData < ActiveRecord::Base

  # Returns all missing relation data points between the given country ids
  # as an array of hashes:
  # { country_from_id, country_from_iso3, country_to_id, country_to_iso3}
  def self.missing_relations(ids, type_with_unit, year)
    ids = Aggregator.normalize_ids(ids)
    Aggregator.check_type_with_unit(type_with_unit)
    year = Aggregator.normalize_year(year)

    ids_for_sql = Aggregator.ids_for_sql(ids)
    type_id = type_with_unit.type.id
    unit_id = type_with_unit.unit.id

    query = "
      SELECT
        countries_from.`id` as `country_from_id`,
        countries_from.`iso3` as `country_from_iso3`,
        countries_to.`id` as `country_to_id`,
        countries_to.`iso3` as `country_to_iso3`
      FROM `countries` AS countries_from
      CROSS JOIN `countries` AS countries_to
      LEFT JOIN
      (
      SELECT DISTINCT `country_from_id`, `country_to_id`, 'present' as `present` FROM `data_values`
      WHERE
        `data_type_id` = #{type_id} AND
        `unit_id` = #{unit_id} AND
        `year` = #{year} AND
        `country_from_id` IN (#{ids_for_sql}) AND
        `country_to_id` IN (#{ids_for_sql})
      ) AS available ON (countries_from.`id` = available.`country_from_id` AND countries_to.`id` = available.`country_to_id`)
      WHERE
        countries_from.`id` <> countries_to.`id` AND
        countries_from.`id` IN (#{ids_for_sql}) AND
        countries_to.`id` IN (#{ids_for_sql}) AND
        `present` IS NULL
    "

    results = self.connection.execute(sanitize_sql(query))
    results.map do |hash|
      {
        country_from_id: hash[0],
        country_from_iso3: hash[1],
        country_to_id: hash[2],
        country_to_iso3: hash[3]
      }
    end
  end

  # Returns all country ids without a single relation given a direction, type and year
  # as an array of { country_id, iso3, direction: 'data_from|data_to' }
  def self.without_relations(ids, type_with_unit, year)
    ids = Aggregator.normalize_ids(ids)
    Aggregator.check_type_with_unit(type_with_unit)
    year = Aggregator.normalize_year(year)

    ids_for_sql = Aggregator.ids_for_sql(ids)
    type_id = type_with_unit.type.id
    unit_id = type_with_unit.unit.id

    query = "
      SELECT countries.`id`, `iso3`, directions.`direction` FROM `countries`
      CROSS JOIN (SELECT 'data_from' as `direction` UNION SELECT 'data_to' as `direction`) directions
      LEFT JOIN
      (
      SELECT DISTINCT `country_from_id` as `id`, 'data_from' as `direction`, 'present' as `present` FROM `data_values`
      WHERE
        `data_type_id` = #{type_id} AND
        `unit_id` = #{unit_id} AND
        `year` = #{year} AND
        `country_from_id` IN (#{ids_for_sql})
      UNION
      SELECT DISTINCT `country_to_id` as `id`, 'data_to' as `direction`, 'present' as `present` FROM `data_values`
      WHERE
        `data_type_id` = #{type_id} AND
        `unit_id` = #{unit_id} AND
        `year` = #{year} AND
        `country_to_id` IN (#{ids_for_sql})
      ) available ON (countries.`id` = available.`id` AND directions.`direction` = available.`direction`)
      WHERE countries.`id` IN (#{ids_for_sql}) AND available.`present` IS NULL
    "

    unless query == sanitize_sql(query)
      raise 'sanitize_sql was necessary!'
    end
    results = self.connection.execute(sanitize_sql(query))
    results.map do |hash|
      {
        country_id: hash[0],
        iso3: hash[1],
        direction: hash[2]
      }
    end
  end

end