# encoding: UTF-8
require 'currency_converter'
require 'csv'

class IndicatorTypeImporter < Importer

  def import
    puts 'IndicatorTypeImporter#import'

    IndicatorType.destroy_all

    IndicatorTypes.definitions.each do |type_definition|
      import_type_and_units(type_definition)
    end
  end

  def import_type_and_units(type_definition)
    puts "Importing #{type_definition.inspect}"

    type_key = type_definition[:type]
    unit_key = type_definition[:unit]
    group = type_definition[:group]
    external = type_definition[:external]
    position = type_definition[:position]
    representation = UNIT_KEY_TO_REPRESENTATION[unit_key]

    type = IndicatorType.where(key: type_key).first_or_initialize
    type.attributes = {
      group: group,
      position: position,
      external: external.nil? ? true : external
    }
    type.save!
    puts "Created indicator type #{type.key}"

    import_unit(unit_key, representation, type)

    CurrencyConverter.other_unit(unit_key) do |unit_key|
      import_unit(unit_key, representation, type)
    end
  end

  def import_unit(unit_key, representation, type)
    unit = Unit.where(key: unit_key).first_or_initialize
    unit.attributes = {
      representation: representation
    }
    if unit.new_record? || !type.units.exists?(id: unit.id)
      type.units << unit
    end
    unit.save!
    puts "Created indicator unit #{unit.key}"
  end

# Constants
# ---------

PROGNOS_KEY_TO_TYPE_AND_UNIT = Hash.new.tap do |hash|
  IndicatorTypes.definitions.each do |type_definition|
    prognos_name = type_definition[:prognos_name]
    next if prognos_name.nil?
    type_key = type_definition[:type]
    unit_key = type_definition[:unit]
    hash[prognos_name] = [type_key, unit_key]
  end
end

UNIT_KEY_TO_REPRESENTATION = {
  'bln_current_dollars' => Unit::ABSOLUTE,
  'bln_real_dollars' => Unit::ABSOLUTE,
  'real_dollars_per_capita' => Unit::ABSOLUTE,

  'bln_current_euros' => Unit::ABSOLUTE,
  'bln_real_euros' => Unit::ABSOLUTE,
  'real_euros_per_capita' => Unit::ABSOLUTE,

  'tsd_persons' => Unit::ABSOLUTE,
  'mln_persons' => Unit::ABSOLUTE,

  'percent' => Unit::PROPORTIONAL,
  'percent_of_gdp' => Unit::PROPORTIONAL,
}

end