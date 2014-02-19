class Keyframe
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Serializers::JSON
  include ActiveModel::Validations

  attr_accessor :countries, :data_type_with_unit, :indicator_types_with_unit,
                :title, :year, :locking, :currency
  attr_writer :max_overall, :indicator_bounds, :yearly_totals

  self.include_root_in_json = false

  def initialize
    self.currency ||= CURRENCY_RULES['info']['default']
    self.countries ||= []
    self.indicator_types_with_unit ||= []
  end

  def self.from_json(input)
    input = input.symbolize_keys
    Keyframe.new.tap do |k|
      k.year = input[:year].to_i
      k.currency = input[:currency]
      k.title = input[:title]
      k.locking = input[:locking]

      # Data type
      data_type, unit = input[:data_type_with_unit]
      data_type = DataType.find_by_key data_type
      unit = Unit.find_by_key unit
      k.set_data_type_with_unit(data_type, unit)

      # Countries
      input[:countries] = [] if input[:countries].nil?
      k.countries = input[:countries].map do |c|
        Country.from_json(c)
      end

      # Indicators
      indicator_types_with_unit = input[:indicator_types_with_unit]
      if indicator_types_with_unit.respond_to? :each
        indicator_types_with_unit.each do |twu|
          indicator_type, unit = twu
          indicator_type = IndicatorType.find_by_key indicator_type
          unit = Unit.find_by_key unit
          k.add_indicator_type_with_unit(indicator_type, unit)
        end
      end

    end
  end

  def attributes
    {
      year: year,
      title: title,
      currency: currency,
      indicator_types_with_unit: indicator_types_with_unit,
      data_type_with_unit: data_type_with_unit,
      elements: elements,
      yearly_totals: yearly_totals,
      max_overall: max_overall,
      indicator_bounds: indicator_bounds,
      locking: locking
    }
  end

  def serializable_hash(options=nil)
    options = {} if options.nil?
    options[:include] = [:countries]
    super(options)
  end

  def add_indicator_type_with_unit(type, unit)
    twu = TypeWithUnit.new
    twu.type = type
    twu.unit = unit
    indicator_types_with_unit << twu
    @elements = nil
  end

  def set_data_type_with_unit(type, unit)
    twu = TypeWithUnit.new
    twu.type = type
    twu.unit = unit
    self.data_type_with_unit = twu
    @elements = nil
  end

  def indicator_types
    indicator_types_with_unit.map &:type
  end

  def indicator_units
    indicator_types_with_unit.map &:unit
  end

  def indicator_bounds
    indicator_types_with_unit.map do |iwu|
      aggregator = IndicatorAggregator.new
      min, max = aggregator.min_max_indicator_all(nested_country_ids, iwu)
      # Convert BigDecimal to Float so the JSON representation
      # is a Number, not a String
      min = min.to_f
      max = max.to_f
      [min, max]
    end
  end

  def data_type
    data_type_with_unit.type
  end

  def data_unit
    data_type_with_unit.unit
  end

  def units
    indicator_units + [data_unit]
  end

  def yearly_totals
    calculate_yearly_totals_and_max unless @yearly_totals
    @yearly_totals
  end

  def max_overall
    calculate_yearly_totals_and_max unless @max_overall
    @max_overall
  end

  def calculate_yearly_totals_and_max
    aggregator = DataAggregator.new
    if countries.any?
      @yearly_totals, @max_overall = aggregator.sum_yearly_for_groups(
        nested_country_ids,
        data_type_with_unit
      )
    else
      # Return a hash with all years, but set the total to zero
      @yearly_totals = aggregator.all_years.reduce({}) do |memo, year|
        memo[year] = 0.0
        memo
      end
      @max_overall = 0.0
    end
  end

  def elements
    return @elements if @elements
    return [] if countries.empty?

    @elements = countries.map do |group|
      Element.new(self, group)
    end

    # Set outgoing and incoming values
    all_incoming = []

    aggregator = DataAggregator.new
    twu = data_type_with_unit

    @elements.each do |element|
      id = element.group_id
      other_ids = all_group_ids - [id]

      unless is_one_only?
        element.outgoing = aggregator.stacked_outgoing(id, other_ids, twu, year)
        all_incoming << aggregator.stacked_incoming(id, other_ids, twu, year)
      end

      if is_one_to_one? or is_one_only?
        element.incoming = aggregator.incoming_top5(id, other_ids, twu, year)
        element.outgoing.merge!(aggregator.outgoing_top5(id, other_ids, twu, year))
      end
    end

    all_incoming.flatten.each do |stacked|
      element = element_by_group_id(stacked[:from_group_id])
      element.outgoing[stacked[:to_group_iso3]][:stacked_amount_to] = stacked[:stacked_amount_to]
    end

    # Set information about missing data points
    aggregator.missing_relations_for_countries(all_country_ids, twu, year).each do |info_hash|
      source_element = element_by_country_id(info_hash[:country_from_id])
      source_element.missing_relations ||= {}
      target_element_iso3 = element_by_country_id(info_hash[:country_to_id]).country_group.iso3

      source_element.missing_relations[target_element_iso3] ||= {}
      source_element.missing_relations[target_element_iso3][info_hash[:country_from_iso3]] ||= []
      source_element.missing_relations[target_element_iso3][info_hash[:country_from_iso3]] << info_hash[:country_to_iso3]
    end

    aggregator.countries_without_relations(all_country_ids, twu, year).each do |info_hash|
      element = element_by_country_id(info_hash[:country_id])
      case info_hash[:direction]
      when 'data_to'   then element.no_incoming << info_hash[:iso3]
      when 'data_from' then element.no_outgoing << info_hash[:iso3]
      end
    end

    @elements
  end

  def all_country_ids
    countries.map(&:country_ids).flatten
  end

  def nested_country_ids
    countries.map(&:country_ids)
  end

  def all_group_ids
    countries.map(&:group_id)
  end

  def is_one_to_one?
    countries.length == 2
  end

  def is_one_only?
    countries.length == 1
  end

  def element_by_group_id(group_id)
    @elements.each do |element|
      return element if (element.country_group.group_id == group_id.to_s)
    end

    nil
  end

  # Returns the element which represents the group of the given country
  def element_by_country_id(country_id)
    @elements.each do |element|
      return element if element.country_ids.include?(country_id)
    end

    nil
  end

end