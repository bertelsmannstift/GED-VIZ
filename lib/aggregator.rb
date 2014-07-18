class Aggregator

  class_attribute :cache_enabled

  # Cache per default
  self.cache_enabled = true

  # Syntactic input checking helpers

  def self.normalize_id(id)
    id = id.to_s
    unless id.match(/^(\d+)|(\d+(-\d+)+)$/)
      raise 'id must be a number or list of numbers'
    end
    id
  end

  def self.normalize_ids(ids)
    raise 'ids must be an array' unless ids.is_a?(Array)
    ids.map do |id|
      normalize_id(id)
    end
  end

  def self.check_type_with_unit(type_with_unit)
    unless type_with_unit.is_a?(TypeWithUnit)
      raise 'type_with_unit must be a TypeWithUnit'
    end
  end

  def self.normalize_year(year)
    year = year.to_s
    raise 'year must be a number' unless year.match(/^\d+$/)
    year
  end

  # Returns all ids of countries and country groups as a comma separated string
  # e.g. ['1-2', '3', '4'] > '1, 2, 3, 4'
  def self.ids_for_sql(ids)
    ids.join('-').split('-').join(', ')
  end

  # Returns all ids a group id as a comma separated string
  # e.g. '1-2-3-4' > '1, 2, 3, 4'
  def self.group_ids_for_sql(id)
    id.split('-').join(', ')
  end

  # Number conversion: Convert numbers and strongs to Float so the JSON
  # representation is always /\d+.\d+/.
  # Also supports Arrays and Hashes, converts values on the nesting level.
  def self.deep_to_f(obj)
    if obj.is_a?(Array)
      obj.map { |v| to_f(v) }
    elsif obj.is_a?(Hash)
      obj.hmap { |k, v| [k, to_f(v)] }
    else
      to_f(obj)
    end
  end

  # Number conversion: Convert BigDecimal, Integer and String to Float
  def self.to_f(v)
    if v.is_a?(BigDecimal) || v.is_a?(Integer) || v.is_a?(String)
      v.to_f
    else
      v
    end
  end

  private

  def cached(*keys)
    unless Aggregator.cache_enabled
      return yield
    end
    key = "aggregate_#{keys.hash}"
    cached = Rails.cache.read(key)
    if cached
      # Rails.logger.debug "Aggregate cache hit #{keys.inspect}"
      cached
    else
      # Rails.logger.debug "Aggregate cache miss #{keys.inspect}"
      calculated = yield
      Rails.cache.write(key, calculated)
      calculated
    end
  end

end