# An Element represents a country or country group
# which is part of a Keyframe.

class Element
  include ActiveModel::Serializers::JSON

  self.include_root_in_json = false

  attr_accessor :country_group, :outgoing, :incoming, :incoming_stacked,
                :no_incoming, :no_outgoing, :missing_relations

  def initialize(keyframe, country_group)
    @keyframe      = keyframe
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

  def attributes
    attrs = {
      sum_in:            sum_in,
      sum_out:           sum_out,
      indicators:        indicators,
      outgoing:          outgoing,
      no_incoming:       no_incoming,
      no_outgoing:       no_outgoing,
      missing_relations: missing_relations
    }
    if incoming
      attrs[:incoming] = incoming
    end
    attrs
  end

  # Outgoing volume as a sum of all relations,
  # even if the target countries are not currently selected
  def sum_out
    aggregator = DataAggregator.new
    value = aggregator.sum_out(country_ids, year, type_with_unit)
    # Convert BigDecimal to Float so the JSON representation
    # is a Number, not a String
    value.to_f
  end

  # Incoming volume as a sum of all relations,
  # even if the source countries are not currently selected
  def sum_in
    aggregator = DataAggregator.new
    value = aggregator.sum_in(country_ids, year, type_with_unit)
    # Convert BigDecimal to Float so the JSON representation
    # is a Number, not a String
    value.to_f
  end

  # All indicator values with tendency and tendency percent
  def indicators
    aggregator = IndicatorAggregator.new
    @keyframe.indicator_types_with_unit.map do |twu|
      hash = aggregator.indicator_value(country_ids, year, twu)
      # Convert BigDecimal to Float so the JSON representation
      # is a Number, not a String
      hash[:value] = hash[:value].to_f
      hash
    end
  end

  # Helper methods for readability

  def country_ids
    @country_group.country_ids
  end

  def group_id
    @country_group.group_id
  end

  def other_ids
    other_countries.map do |group|
      group.country_ids
    end.flatten
  end

  def other_countries
    @keyframe.countries - [@country_group]
  end

  def year
    @keyframe.year
  end

  def type_with_unit
    @keyframe.data_type_with_unit
  end

  def data_type
    @keyframe.data_type
  end

end