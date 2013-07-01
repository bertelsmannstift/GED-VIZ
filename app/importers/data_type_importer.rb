class DataTypeImporter < Importer

  TYPE_NAME_TO_KEY = {
    'Import'                                       => 'import',
    'Inflows of foreign population by nationality' => 'migration',
    'Foreign Claims'                               => 'claims'
  }

  UNIT_NAME_TO_ATTRIBUTES = {
    'Bln. US-$' => {
      key:            'bln_current_dollars',
      representation: Unit::ABSOLUTE
    },
    'Bln. Us-$' => {
      key:            'bln_current_dollars',
      representation: Unit::ABSOLUTE
    },
    'Mio. US-$' => {
      key:            'mln_current_dollars',
      representation: Unit::ABSOLUTE
    },
    'Bln. EUR' => {
      key:            'bln_current_euros',
      representation: Unit::ABSOLUTE
    },
    'Mio. EUR' => {
      key:            'mln_current_euros',
      representation: Unit::ABSOLUTE
    },

    'Tsd. Persons' => {
      key:            'tsd_persons',
      representation: Unit::ABSOLUTE
    }
  }

  DATA_TYPE_KEY_TO_UNIT_KEYS = {
    'import'    => ['bln_current_dollars', 'bln_current_euros'],
    'migration' => ['tsd_persons'],
    'claims'    => ['bln_current_dollars', 'bln_current_euros']
  }

  def import
    create_units
    create_types
  end

  def create_units
    puts 'DataTypeImporter#create_units'

    # Create units
    UNIT_NAME_TO_ATTRIBUTES.each do |unit_name, attributes|
      unit = Unit.where(key: attributes[:key]).first_or_initialize
      unit.attributes = {
        representation: attributes[:representation]
      }
      unit.save!
      puts "Created data unit #{unit.inspect}"
    end
  end

  def create_types
    puts 'DataTypeImporter#create_types'
    DataType.delete_all

    TYPE_NAME_TO_KEY.each do |name, key|
      unit_ids = Unit.where(key: DATA_TYPE_KEY_TO_UNIT_KEYS.fetch(key)).pluck(:id)
      type = DataType.create!(
        key: key,
        unit_ids: unit_ids
      )
      puts "Created data type #{type.inspect}"
    end
  end

end
