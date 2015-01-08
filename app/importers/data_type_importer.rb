class DataTypeImporter < Importer

  TYPE_NAME_TO_KEY = {
    'Total Imports' => { key: 'import'},
    'Import' => { key: 'import' },
    'Inflows of foreign population by nationality' => { key: 'migration' },
    'Foreign Claims' => { key: 'claims' },
    'Computer' => { key: 'computers', parent: 'import' },
    'Beer' => { key: 'beer', parent: 'import' },
    'Cereals' => { key: 'cereals', parent: 'import' },
    'Chemicals' => { key: 'chemicals', parent: 'import' },
    'Clothing' => { key: 'clothing', parent: 'import' },
    'Coal' => { key: 'coal', parent: 'import' },
    'Electric Current' => { key: 'electricity', parent: 'import' },
    'Iron and Steel' => { key: 'steel', parent: 'import' },
    'Machinery and transport equipment' => { key: 'machinery', parent: 'import' },
    'Cars' => { key: 'cars', parent: 'import' },
    'Natural Gas' => { key: 'gas', parent: 'import' },
    'Petroleum Oil' => { key: 'oil', parent: 'import' },
    'Telecommunicatios equipment' => { key: 'telecommunication', parent: 'import' },
    'Vegetables and Fruit' => { key: 'vegetables', parent: 'import' }
  }

  UNIT_NAME_TO_ATTRIBUTES = {
    # US dollar
    'Bln. US-$' => {
      key: 'bln_current_dollars',
      representation: Unit::ABSOLUTE
    },
    'Bln. Us-$' => {
      key: 'bln_current_dollars',
      representation: Unit::ABSOLUTE
    },
    'Mio. US-$' => {
      key: 'mln_current_dollars',
      representation: Unit::ABSOLUTE
    },

    # Euro
    'Bln. EUR' => {
      key: 'bln_current_euros',
      representation: Unit::ABSOLUTE
    },
    'Mio. EUR' => {
      key: 'mln_current_euros',
      representation: Unit::ABSOLUTE
    },

    # Persons
    'Persons' => {
      key: 'persons',
      representation: Unit::ABSOLUTE
    },
    'Tsd. Persons' => {
      key: 'tsd_persons',
      representation: Unit::ABSOLUTE
    }
  }

  TYPE_KEY_TO_UNIT_KEYS = {
    'import' => %w(bln_current_dollars bln_current_euros),
    'migration' => %w(persons),
    'claims' => %w(bln_current_dollars bln_current_euros),
    'trade' => %w(bln_current_dollars bln_current_euros),
    'computers' => %w(bln_current_dollars bln_current_euros),
    'beer' => %w(bln_current_dollars bln_current_euros),
    'cereals' => %w(bln_current_dollars bln_current_euros),
    'chemicals' => %w(bln_current_dollars bln_current_euros),
    'clothing' => %w(bln_current_dollars bln_current_euros),
    'coal' => %w(bln_current_dollars bln_current_euros),
    'electricity' => %w(bln_current_dollars bln_current_euros),
    'steel' => %w(bln_current_dollars bln_current_euros),
    'machinery' => %w(bln_current_dollars bln_current_euros),
    'cars' => %w(bln_current_dollars bln_current_euros),
    'gas' => %w(bln_current_dollars bln_current_euros),
    'oil' => %w(bln_current_dollars bln_current_euros),
    'telecommunication' => %w(bln_current_dollars bln_current_euros),
    'vegetables' => %w(bln_current_dollars bln_current_euros)
  }

  def import
    create_units
    create_types
  end

  def create_units
    puts 'DataTypeImporter#create_units'

    UNIT_NAME_TO_ATTRIBUTES.each do |name, attributes|
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

    TYPE_NAME_TO_KEY.values.uniq.each do |info|
      unit_keys = TYPE_KEY_TO_UNIT_KEYS.fetch(info[:key])
      unit_ids = Unit.where(key: unit_keys).pluck(:id)

      type = DataType.where(key: info[:key]).first_or_initialize
      type.attributes = {
        parent_key: info[:parent],
        unit_ids: unit_ids
      }
      type.save!
      puts "Created data type #{type.inspect}"
    end
  end

end
