class Keyframe
  # Metadata properties
  attr_accessor :countries, :data_type_with_unit, :indicator_types_with_unit,
                :title, :year, :locking, :currency
  # Data properties
  attr_accessor :indicator_bounds, :max_overall, :yearly_totals, :elements

  def initialize
    self.currency = CURRENCY_RULES['info']['default']
    self.countries = []
    self.indicator_types_with_unit = []
  end

  def self.from_json(hash)
    hash = hash.recursive_symbolize_keys
    #puts "Keyframe.from_json input\n#{hash}\n\n"

    keyframe = Keyframe.new

    # Metadata (mandatory)
    # --------------------

    keyframe.title = hash[:title]
    keyframe.year = hash[:year].to_i
    keyframe.currency = hash[:currency]
    keyframe.locking = hash[:locking]

    # Data type
    data_type, unit = hash[:data_type_with_unit]
    data_type = DataType.find_by_key(data_type)
    unit = Unit.find_by_key(unit)
    keyframe.set_data_type_with_unit(data_type, unit)

    # Countries
    countries = hash[:countries] || []
    keyframe.countries = countries.map do |c|
      Country.from_json(c)
    end

    # Indicators
    indicator_types_with_unit = hash[:indicator_types_with_unit] || []
    indicator_types_with_unit.each do |type_with_unit|
      indicator_type, unit = type_with_unit
      indicator_type = IndicatorType.find_by_key(indicator_type)
      unit = Unit.find_by_key(unit)
      keyframe.add_indicator_type_with_unit(indicator_type, unit)
    end

    # Data properties (optional)
    # --------------------------

    # indicator_bounds and max_overall might be saved as ints,
    # convert them to float
    indicator_bounds = hash[:indicator_bounds]
    if indicator_bounds
      keyframe.indicator_bounds = indicator_bounds.map do |pair|
        pair.map &:to_f
      end
    end

    max_overall = hash[:max_overall]
    keyframe.max_overall = max_overall.to_f if max_overall

    yearly_totals = hash[:yearly_totals]
    keyframe.yearly_totals = yearly_totals if yearly_totals

    # Elements
    elements = hash[:elements]
    if elements
      keyframe.elements = elements.each_with_index.map do |hash, index|
        country_group = keyframe.countries[index]
        Element.from_json(keyframe, country_group, hash)
      end
    end

    #puts "Keyframe.from_json output\n#{keyframe.inspect}\n\n"
    keyframe
  end

  def as_json(options = nil)
    #puts 'Keyframe#as_json'
    {
      year: year,
      title: title,
      currency: currency,
      indicator_types_with_unit: indicator_types_with_unit,
      data_type_with_unit: data_type_with_unit,
      countries: countries,
      elements: elements,
      yearly_totals: yearly_totals,
      max_overall: max_overall,
      indicator_bounds: indicator_bounds,
      locking: locking
    }
  end

  # Types and units

  def add_indicator_type_with_unit(type, unit)
    twu = TypeWithUnit.new
    twu.type = type
    twu.unit = unit
    indicator_types_with_unit << twu
    # Invalidate data
    @elements = nil
  end

  def set_data_type_with_unit(type, unit)
    twu = TypeWithUnit.new
    twu.type = type
    twu.unit = unit
    self.data_type_with_unit = twu
    # Invalidate data
    @elements = nil
  end

  # Data properties

  def indicator_bounds
    @indicator_bounds ||= calculate_indicator_bounds
  end

  def yearly_totals
    unless @yearly_totals
      @yearly_totals, @max_overall = calculate_yearly_totals_and_max_overall
    end
    @yearly_totals
  end

  def max_overall
    unless @yearly_totals
      @yearly_totals, @max_overall = calculate_yearly_totals_and_max_overall
    end
    @max_overall
  end

  def elements
    if @elements
      #puts 'Keyframe#elements: reuse elements'
      @elements
    else
      #puts 'Keyframe#elements: create new elements'
      @elements = calculate_elements
    end
  end

  def all_country_ids
    countries.map(&:country_ids).flatten
  end

  # Recalculate the data
  def calculate_data!
    @indicator_bounds = calculate_indicator_bounds
    @yearly_totals, @max_overall = calculate_yearly_totals_and_max_overall
    @elements = calculate_elements
  end

  private

  def calculate_yearly_totals_and_max_overall
    aggregator = DataAggregator.new
    if countries.any?
      yearly_totals, max_overall = aggregator.sum_yearly_for_groups(
          nested_country_ids, data_type_with_unit
      )
    else
      # Return a hash with all years, but set the total to zero
      yearly_totals = aggregator.all_years.reduce({}) do |memo, year|
        memo[year] = 0.0
        memo
      end
      max_overall = 0.0
    end
    [yearly_totals, max_overall]
  end

  def calculate_indicator_bounds
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

  def calculate_elements
    return [] if countries.empty?

    elements = countries.map do |group|
      Element.new(self, group)
    end

    # Set outgoing and incoming values
    all_incoming = []

    aggregator = DataAggregator.new
    twu = data_type_with_unit

    elements.each do |element|
      id = element.country_group.group_id
      other_ids = all_group_ids - [id]

      unless is_one?
        element.outgoing = aggregator.stacked_outgoing(id, other_ids, twu, year)
        all_incoming << aggregator.stacked_incoming(id, other_ids, twu, year)
      end

      if is_one? || is_one_to_one?
        element.incoming = aggregator.incoming_top5(id, other_ids, twu, year)
        element.outgoing.merge!(aggregator.outgoing_top5(id, other_ids, twu, year))
      end
    end

    all_incoming.flatten.each do |stacked|
      element = element_by_group_id(elements, stacked[:from_group_id])
      element.outgoing[stacked[:to_group_iso3]][:stacked_amount_to] = stacked[:stacked_amount_to]
    end

    # Add missing relations to the elements
    aggregator.missing_relations_for_countries(all_country_ids, twu, year).each do |hash|
      country_from_id = hash[:country_from_id]
      country_from_iso3 = hash[:country_from_iso3]
      country_to_iso3 = hash[:country_to_iso3]
      country_to_id = hash[:country_to_id]

      source_element = element_by_country_id(elements, country_from_id)
      target_element = element_by_country_id(elements, country_to_id)
      target_element_iso3 = target_element.country_group.iso3

      missing_relation = {}
      missing_relation[country_from_iso3] = [country_to_iso3]
      source_element.missing_relations[target_element_iso3] ||= missing_relation
    end

    # Add countries without relations to no_incoming and no_outgoing
    aggregator.countries_without_relations(all_country_ids, twu, year).each do |hash|
      element = element_by_country_id(elements, hash[:country_id])
      case hash[:direction]
        when 'data_to'   then element.no_incoming << hash[:iso3]
        when 'data_from' then element.no_outgoing << hash[:iso3]
      end
    end

    elements
  end

  # Element finders

  def element_by_group_id(elements, group_id)
    group_id = group_id.to_s
    elements.find do |element|
      element.country_group.group_id == group_id
    end
  end

  def element_by_country_id(elements, country_id)
    elements.find do |element|
      element.country_ids.include?(country_id)
    end
  end

  # Country helpers

  def nested_country_ids
    countries.map(&:country_ids)
  end

  def all_group_ids
    countries.map(&:group_id)
  end

  def is_one_to_one?
    countries.length == 2
  end

  def is_one?
    countries.length == 1
  end

end