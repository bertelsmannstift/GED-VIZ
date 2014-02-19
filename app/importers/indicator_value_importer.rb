require 'currency_converter'

class IndicatorValueImporter < Importer

  # The main input file
  INPUT_FILENAME = 'Prognos_out_unilateral_12maerz13.csv'

  attr_reader :all_country_ids, :country_id_by_iso3, :type_id_by_key, :unit_id_by_key

  def setup
    @all_country_ids = Country.pluck(:id).sort
    @country_id_by_iso3 = Hash.new do |hash, key|
      hash[key] = Country.find_by_iso3!(key).id
    end
    @type_id_by_key = Hash.new do |hash, key|
      hash[key] = IndicatorType.find_by_key!(key).id
    end
    @unit_id_by_key = Hash.new do |hash, key|
      hash[key] = Unit.find_by_key!(key).id
    end
  end

  def import
    puts 'IndicatorValueImporter#import'
    IndicatorValue.delete_all
    import_base_values
    calculate_derived_values
    calculate_quotient_values
    calculate_currencies
    calculate_tendencies
  end

  # Base values
  # -----------

  def import_base_values
    puts 'IndicatorValueImporter#import_base_values'
    file = folder.join(INPUT_FILENAME)
    CSV.foreach(file, headers: true, return_headers: false, col_sep: ';') do |row|
      # Ignore currency conversion
      next if row[0] == '?_ex_$'
      import_base_value(row)
    end
  end

  def import_base_value(row)
    # Row schema:
    # VarCode;Country;Variable;Unit;Year;Value;Source
    prognos_name = row[0].split('_')[1]
    type_key, unit_key = IndicatorTypes.prognos_key_to_type_and_unit[prognos_name]
    iso3  = row[1].downcase
    year  = row[4]
    country_id = country_id_by_iso3[iso3]

    value = Float(row[5]) rescue false
    return unless value

    type_id = type_id_by_key[type_key]
    unit_id = unit_id_by_key[unit_key]

    if type_id.nil? || unit_id.nil?
      puts "\tCould not find IndicatorType for type #{type_key} or unit #{unit_key}."
      puts "\trow #{row.index} #{row.inspect}"
      puts "\t#{prognos_name}, #{type_key}, #{unit_key}, #{iso3}, #{year}, #{value}"
      return
    end

    IndicatorValue.create!(
      indicator_type_id: type_id,
      unit_id: unit_id,
      country_id: country_id,
      year: year,
      value: value
    )
  end

  # Calculate simple derived values
  # -------------------------------

  def calculate_derived_values
    IndicatorTypes.derived_types.each do |type_definition|
      twu = type_definition[:twu]
      source = type_definition[:source]
      converter = type_definition[:converter]
      puts "calculate_derived_values for #{twu} from #{source}"
      source_values = IndicatorValue.where(
        indicator_type_id: source.type.id,
        unit_id: source.unit.id
      )
      source_values.each do |indicator_value|
        value = converter.call(indicator_value.value)
        #puts "\tconverted #{indicator_value.value} to #{value}"
        IndicatorValue.create!(
          indicator_type_id: twu.type.id,
          unit_id: twu.unit.id,
          country_id: indicator_value.country_id,
          year: indicator_value.year,
          value: value
        )
      end
    end
  end

  # Calculate derived values using quotient formulas
  # ------------------------------------------------

  def calculate_quotient_values
    puts 'IndicatorValueImporter#calculate_quotient_values'
    years = IndicatorValue.uniq.pluck(:year)

    IndicatorTypes.quotient_types.each do |type_definition|
      puts "calculate_quotient_values for #{type_definition[:twu]} from #{type_definition[:dividend]} and #{type_definition[:divisor]}"
      all_country_ids.each do |country_id|
        years.each do |year|
          calculate_quotient_value(type_definition, country_id, year)
        end
      end
    end
  end

  def calculate_quotient_value(type_definition, country_id, year)
    twu = type_definition[:twu]
    dividend_twu = type_definition[:dividend]
    divisor_twu = type_definition[:divisor]
    source_types = [ dividend_twu, divisor_twu ]
    #puts "calculate_quotient_value #{twu} from #{dividend_twu} / #{divisor_twu}, country: #{country_id} year: #{year}"

    dividend, divisor = source_types.map do |source|
      IndicatorValue.where(
        indicator_type_id: source.type.id,
        unit_id: source.unit.id,
        country_id: country_id,
        year: year
      ).pluck(:value).first
    end

    if dividend.nil? || divisor.nil?
      puts "\tCould not find sources for quotient type #{twu},\n"
      puts "\t\tdividend: #{dividend_twu}, divisor: #{divisor_twu}"
      puts "\t\tcountry: #{country_id}, year: #{year}\n"
      return
    end

    # Conversion
    converter = type_definition[:converter]
    if converter.present?
      dividend, divisor = converter.call(dividend, divisor, dividend_twu, divisor_twu)
    end

    # Calculate quotient
    value = dividend / divisor
    #puts "\t#{year}: #{value}"

    IndicatorValue.create!(
      indicator_type_id: twu.type.id,
      unit_id: twu.unit.id,
      country_id: country_id,
      year: year,
      value: value
    )
  end

  # Currency conversion
  # -------------------

  def calculate_currencies
    puts 'IndicatorValueImporter#calculate_currencies'
    IndicatorValue.all.each do |indicator_value|
      type_id = indicator_value.indicator_type_id
      unit_key = indicator_value.unit.key
      country_id = indicator_value.country_id
      year = indicator_value.year
      value = indicator_value.value

      CurrencyConverter.convert unit_key, year, value do |new_value, new_unit_key|
        return unless new_value
        #puts "\tconvert #{unit_key} to #{new_unit_key}: " +
        #  "#{indicator_value.country.iso3} #{year}, #{value} > #{new_value}"
        new_unit_id = unit_id_by_key[new_unit_key]
        IndicatorValue.create!(
          indicator_type_id: type_id,
          unit_id: new_unit_id,
          country_id: country_id,
          year: year,
          value: new_value
        )
      end
    end
  end

  # Tendencies
  # ----------

  def calculate_tendencies
    puts 'IndicatorValueImporter#calculate_tendencies'

    # For all countries…
    all_country_ids.each do |country_id|
      puts "\tcountry #{country_id}"

      # For all types…
      IndicatorType.all.each do |type|

        # For all units…
        type.units.each do |unit|
          #puts "\t#{type.key}(#{unit.key})"
          old_value = nil

          criteria = {
            indicator_type_id: type.id,
            unit_id: unit.id,
            country_id: country_id
          }

          # For all values…
          IndicatorValue.where(criteria).order(:year).each do |indicator_value|
            new_value = indicator_value.value
            aggregator = IndicatorAggregator.new
            tendency_percent = aggregator.calculate_percent_difference(
              unit, new_value, old_value
            )
            tendency = aggregator.percent_to_tendency unit, tendency_percent
            #puts "tendency for country #{country_id} #{type.key}(#{unit.key}) #{indicator_value.year}:"
            #puts "\t#{old_value} > #{new_value}, % #{percent}, tendency #{tendency}"
            indicator_value.attributes = {
              tendency: tendency,
              tendency_percent: tendency_percent
            }
            indicator_value.save!
            old_value = new_value
          end
        end
      end
    end
  end

end