# An Element represents a country or country group
# which is part of a Keyframe.

class Element
  attr_accessor :sum_out, :sum_in, :indicators,
                :keyframe, :country_group,
                :outgoing, :incoming,
                :no_incoming, :no_outgoing,
                :missing_relations

  def initialize(keyframe, country_group)
    @keyframe = keyframe
    @country_group = country_group

    @outgoing = {}
    @incoming = {}

    # List of country ids in this group
    @no_incoming = []
    # List of country ids in this group
    @no_outgoing = []
    # Lists of missing relations as value for targeted group as key
    @missing_relations = {}
  end

  # Expects a hash with deep symbol keys
  def self.from_json(keyframe, country_group, hash)
    # Convert Integers and Strings to Float
    to_f = proc do |k, v|
      [k, v.is_a?(Integer) || v.is_a?(String) ? v.to_f : v]
    end

    element = Element.new(keyframe, country_group)
    # Floats
    element.sum_in = hash[:sum_in].to_f
    element.sum_out = hash[:sum_out].to_f
    # Array of Hashes
    element.indicators = hash[:indicators].map do |indicator|
      indicator.hmap &to_f
    end
    # Arrays of Hashes
    element.outgoing = hash[:outgoing].hmap &to_f
    element.incoming = hash[:incoming].hmap &to_f
    # Arrays of Strings
    element.no_incoming = hash[:no_incoming]
    element.no_outgoing = hash[:no_outgoing]
    # Hash with Strings
    element.missing_relations = hash[:missing_relations]

    element
  end

  def as_json(options = nil)
    hash = {
      sum_in: sum_in,
      sum_out: sum_out,
      indicators: indicators,
      outgoing: outgoing,
      no_incoming: no_incoming,
      no_outgoing: no_outgoing,
      missing_relations: missing_relations
    }
    if incoming
      hash[:incoming] = incoming
    end
    hash
  end

  # Outgoing volume as a sum of all relations,
  # even if the target countries are not currently selected
  def sum_out
    return @sum_out if @sum_out
    aggregator = DataAggregator.new
    @sum_out = Aggregator.deep_to_f(
      aggregator.sum_out(country_ids, year, type_with_unit)
    )
  end

  # Incoming volume as a sum of all relations,
  # even if the source countries are not currently selected
  def sum_in
    return @sum_in if @sum_in
    aggregator = DataAggregator.new
    @sum_in = Aggregator.deep_to_f(
      aggregator.sum_in(country_ids, year, type_with_unit)
    )
  end

  # All indicator values
  def indicators
    return @indicators if @indicators
    aggregator = IndicatorAggregator.new
    @indicators = @keyframe.indicator_types_with_unit.map do |twu|
      Aggregator.deep_to_f(
        aggregator.indicator_value(country_ids, year, twu)
      )
    end
  end

  # Helper methods for readability

  def country_ids
    @country_group.country_ids
  end

  private

  def year
    @keyframe.year
  end

  def type_with_unit
    @keyframe.data_type_with_unit
  end

end