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
    external = type_definition[:external]
    position = type_definition[:position]

    # Create/update type
    type = IndicatorType.where(key: type_key).first_or_initialize
    type.attributes = {
      group: group,
      position: position,
      external: external.nil? ? true : external
    }
    type.save!
    puts "Created indicator type #{type.key}"

    # Create/update type
    import_unit(unit_key, type)

    converted_unit_key = CurrencyConverter.other_unit(unit_key)
    if converted_unit_key
      import_unit(converted_unit_key, type)
    end
  end

  def import_unit(unit_key, type)
    unit = Unit.where(key: unit_key).first_or_initialize
    unit_definition = IndicatorTypes.unit_definitions[unit_key]
    unit.attributes = {
      representation: unit_definition[:representation],
      position: unit_definition[:position]
    }
    if unit.new_record? || !type.units.exists?(id: unit.id)
      type.units << unit
    end
    unit.save!
    puts "Created indicator unit #{unit.key}"
  end

end