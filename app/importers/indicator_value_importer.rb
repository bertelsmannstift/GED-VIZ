require 'currency_converter'

class IndicatorValueImporter < Importer

  # The main input file
  INPUT_FILENAME = 'Prognos_out_unilateral_2015-10-28.csv'

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
    options = { headers: true, return_headers: false, col_sep: ';' }
    CSV.foreach(file, options) do |row|
      # Ignore currency conversion
      next if exchange_rate?(row)
      begin
        import_base_value(row)
      rescue => e
        puts "Error importing row #{$.} #{row.inspect}"
        #raise e
      end
    end
  end

  def exchange_rate?(row)
    row[0] == '?_ex_$' || row[0].match(/_vn531_\$$/)
  end

  def import_base_value(row)
    # Row schema:
    # VarCode;Country;Variable;Unit;Year;Value;Source
    #puts "import_base_value #{row.inspect}"

    # Type and unit
    prognos_name = row[0].split('_')[1]
    begin
      type_key, unit_key = IndicatorTypes.prognos_key_to_type_and_unit.fetch(prognos_name)
      type_id = type_id_by_key[type_key]
      unit_id = unit_id_by_key[unit_key]
    rescue KeyError, ActiveRecord::RecordNotFound => e
      puts "\tCould not find type “#{type_key}” or unit “#{unit_key}” " +
        "for Prognos name “#{prognos_name}”"
      raise e
    end

    # Country ISO3
    iso3 = row[1].downcase
    begin
      country_id = country_id_by_iso3[iso3]
    rescue ActiveRecord::RecordNotFound => e
      puts "\tCould not find country #{iso3}"
      raise e
    end

    # Year
    year = row[4]

    # Value
    value = row[5]
    begin
      value = Float(value)
    rescue ArgumentError => e
      puts "\tCould not process value #{value}"
      raise e
    end

    #puts "#{prognos_name} #{type_key} #{unit_key} #{year} #{country_id}"

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
      puts "\tCould not find sources for quotient type #{twu},"
      puts "\t\tdividend: #{dividend_twu}, divisor: #{divisor_twu}"
      puts "\t\tcountry: #{country_id}, year: #{year}"
      return
    end

    # Conversion
    converter = type_definition[:converter]
    if converter.present?
      dividend, divisor = converter.call(dividend, divisor, dividend_twu, divisor_twu)
    end

    # Calculate quotient
    value = dividend / divisor

    #puts "\t#{year}: #{dividend} / #{divisor} = #{value}"

    unless value.finite?
      puts "\tquotient is not finite:"
      puts "\t\t#{dividend.class} #{dividend} / #{divisor.class} #{divisor} = #{value.class} #{value}"
      return
    end

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
