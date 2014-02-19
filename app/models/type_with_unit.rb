class TypeWithUnit

  attr_accessor :type, :unit

  # Don’t initialize type and unit in the constructor
  # to allow for serialization

  # initialize accepts objects or keys for data_type, indicator_type and unit
  def initialize(options = nil)
    if options
      data_type = options[:data_type]
      indicator_type = options[:indicator_type]
      unit = options[:unit]

      if data_type.is_a? DataType
        @type = data_type
      elsif data_type
        @type = DataType.where(key: data_type).first

      elsif indicator_type.is_a? IndicatorType
        @type = indicator_type
      elsif indicator_type
        @type = IndicatorType.where(key: indicator_type).first
      end

      if unit.is_a? Unit
        @unit = unit
      elsif unit
        @unit = Unit.where(key: unit).first
      end

    end
  end

  def as_json(*args)
    [@type.key, @unit.key]
  end

  def to_s
    "#{@type.key}(#{@unit.key})"
  end

  def set_data_type_and_unit(twu)
    @type = DataType.where(key: twu[0]).first
    @unit = Unit.where(key: twu[1]).first
  end

  def set_indicator_type_and_unit(twu)
    @type = IndicatorType.where(key: twu[0]).first
    @unit = Unit.where(key: twu[1]).first
  end

  def ==(other)
    self.class == other.class &&
      self.type == other.type &&
      self.unit == other.unit
  end
  alias_method :eql?, :==
end