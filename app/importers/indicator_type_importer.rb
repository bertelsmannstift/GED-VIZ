# encoding: UTF-8
require 'currency_converter'
require 'csv'

class IndicatorTypeImporter < Importer

  def import
    puts 'IndicatorTypeImporter#import'

    IndicatorType.destroy_all

    IndicatorTypes.type_definitions.each do |type_definition|
      import_type_and_units(type_definition)
    end
  end

  def import_type_and_units(type_definition)
    puts "Importing #{type_definition.inspect}"

    type_key = type_definition[:type]
    unit_key = type_definition[:unit]
    group = type_definition[:group]
    position = type_definition[:position]
    external = type_definition[:external]

    # Create/update type and connect units
    type = import_type(type_key, group, position, external)
    import_unit(unit_key, type)

    # Convert unit
    converted_unit_key = CurrencyConverter.other_unit(unit_key)
    if converted_unit_key
      import_unit(converted_unit_key, type)
    end
  end

  def import_type(key, group, position, external)
    type = IndicatorType.where(key: key).first_or_initialize
    type.attributes = {
      group: group,
      position: position,
      external: external.nil? ? true : external
    }
    type.save!
    puts "Created indicator type #{type.key}"
    type
  end

  # Creates/updates a unit for a given key and indicator type
  def import_unit(key, indicator_type)
    unit_definition = IndicatorTypes.unit_definitions[key]

    unit = Unit.where(key: key).first_or_initialize
    unit.attributes = {
      representation: unit_definition[:representation],
      position: unit_definition[:position]
    }
    if unit.new_record? || !indicator_type.units.exists?(id: unit.id)
      indicator_type.units << unit
    end
    unit.save!
    puts "Created indicator unit #{unit.key}"
    unit
  end

end