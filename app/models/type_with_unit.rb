class TypeWithUnit

  attr_accessor :type, :unit

  # Don’t initialize type and unit in the constructor
  # to allow for serialization

  def initialize(options = nil)
    if options
      if options[:data_type].is_a? DataType
        @type = options[:data_type]
      elsif options[:data_type]
        @type = DataType.where(key: options[:data_type]).first

      elsif options[:indicator_type].is_a? IndicatorType
        @type = options[:indicator_type]
      elsif options[:indicator_type]
        @type = IndicatorType.where(key: options[:indicator_type]).first
      end

      if options[:unit].is_a? Unit
        @unit = options[:unit]
      elsif options[:unit]
        @unit = Unit.where(key: options[:unit]).first
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

  def hash
    [type, unit].hash
  end

  def eql?(other)
    if other.class == self.class
      self.hash.eql?(other.hash)
    else
      false
    end
  end

end