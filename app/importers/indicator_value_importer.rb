require 'currency_converter'

class IndicatorValueImporter < Importer

  # The main input file
  INPUT_FILENAME = 'Prognos_out_unilateral_12maerz13.csv'

  attr_reader :all_country_ids, :country_ids_by_iso3, :type_ids_by_key, :unit_ids_by_key

  def setup
    @all_country_ids = Country.pluck(:id).sort
    @country_ids_by_iso3 = Hash.new do |hash, key|
      hash[key] = Country.find_by_iso3!(key).id
    end
    @type_ids_by_key = Hash.new do |hash, key|
      hash[key] = IndicatorType.find_by_key!(key).id
    end
    @unit_ids_by_key = Hash.new do |hash, key|
      hash[key] = Unit.find_by_key!(key).id
    end
  end

  def import
    puts 'IndicatorValueImporter#import'
    IndicatorValue.delete_all
    import_base_values
    calculate_mln_persons
    calculate_quotient_values
    calculate_per_capita_values
    calculate_currencies
    calculate_tendencies
  end

  # Base values
  # -----------

  def import_base_values
    puts 'IndicatorValueImporter#import_base_values'
    file = folder.join(INPUT_FILENAME)
    CSV.foreach(file, headers: true, return_headers: false, col_sep: ';') do |row|
      # VarCode;Land;Variable;Einheit;Jahr;Wert;Quelle

      # Ignore currency conversion
      next if row[0] == '?_ex_$'

      import_base_value(row)
    end
  end

  def import_base_value(row)
    prognos_name = row[0].split('_')[1]
    type_key, unit_key = IndicatorTypeImporter::PROGNOS_KEY_TO_TYPE_AND_UNIT[prognos_name]
    iso3  = row[1].downcase
    year  = row[4]
    country_id = country_ids_by_iso3[iso3]

    value = Float(row[5]) rescue false
    return unless value

    type_id = type_ids_by_key[type_key]
    unit_id = unit_ids_by_key[unit_key]

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

  # Calculate derived mln_persons values from tsd_persons
  # -----------------------------------------------------

  def calculate_mln_persons
    puts 'IndicatorValueImporter#calculate_mln_persons'

    IndicatorTypes.mln_persons_types.each do |derived, source|
      puts "calculate_mln_persons for #{derived}"
      source_values = IndicatorValue.where(
        indicator_type_id: source.type.id,
        unit_id: source.unit.id
      )
      source_values.each do |indicator_value|
        IndicatorValue.create!(
          indicator_type_id: derived.type.id,
          unit_id: derived.unit.id,
          country_id: indicator_value.country_id,
          year: indicator_value.year,
          value: indicator_value.value / 1000.0
        )
      end
    end
  end

  # Calculate derived values using quotient formulas
  # ------------------------------------------------

  def calculate_quotient_values
    puts 'IndicatorValueImporter#calculate_quotient_values'
    years = IndicatorValue.uniq.pluck(:year)

    IndicatorTypes.quotient_types.each do |twu, fraction|
      puts "calculate_quotient_values for #{twu}"
      all_country_ids.each do |country_id|
        years.each do |year|
          calculate_quotient_value(twu, fraction, country_id, year)
        end
      end
    end
  end

  def calculate_quotient_value(twu, fraction, country_id, year)
    #puts "calculate_quotient_value #{twu} #{fraction} #{country_id} #{year}"
    value = IndicatorAggregator.new.quotient_indicator_value([country_id], year, fraction)

    if value.nan?
      puts "\tCould not find sources for quotient type #{twu},\n"
      puts "\t\tdividend: #{fraction[0]}, divisor: #{fraction[1]}"
      puts "\t\tcountry: #{country_id}, year: #{year}\n"
      return
    end

    #puts "\t\t#{year}: #{value}"
    IndicatorValue.create!(
      indicator_type_id: twu.type.id,
      unit_id: twu.unit.id,
      country_id: country_id,
      year: year,
      value: value
    )
  end

  # Calculate derive per capita values
  # ----------------------------------

  def calculate_per_capita_values
    puts 'IndicatorValueImporter#calculate_per_capita_values'

    IndicatorTypes.per_capita_types.each do |twu, fraction|
      dividend_twu, divisor_twu = fraction
      puts "calculate_per_capita_values for #{twu} using #{dividend_twu} and #{divisor_twu}"

      IndicatorValue.where(
        indicator_type_id: twu.type.id,
        unit_id: twu.unit.id
      ).destroy_all

      dividend_values = IndicatorValue.where(
        indicator_type_id: dividend_twu.type.id,
        unit_id: dividend_twu.unit.id
      )

      puts "\tdividend_values found: #{dividend_values.length}"

      dividend_values.each do |dividend_value|
        calculate_per_capita_value(twu, dividend_twu, dividend_value, divisor_twu)
      end
    end
  end

  def calculate_per_capita_value(twu, dividend_twu, dividend_value, divisor_twu)
    #puts "calculate_per_capita_value for #{twu} country: #{dividend_value.country.iso3} year: #{dividend_value.year}"

    divisor_value = IndicatorValue.where(
      indicator_type_id: divisor_twu.type.id,
      unit_id: divisor_twu.unit.id,
      country_id: dividend_value.country_id,
      year: dividend_value.year
    ).first

    unless divisor_value
      puts "\n\tCould not find divisor for per capita type #{twu},\n"
      puts "\tdividend_twu: #{dividend_twu}, divisor_twu: #{divisor_twu}"
      return
    end

    dividend = dividend_value.value
    divisor = divisor_value.value

    # Convert billion dollars to dollars
    if %w(bln_real_dollars bln_current_dollars').include? dividend_twu.unit.key
      dividend = dividend * 1000000000
    end

    # Convert thousand persons to persons
    divisor = divisor * 1000

    value = dividend / divisor
    #puts "per capita: #{dividend} / #{divisor} = #{value}"

    record = {
      indicator_type_id: twu.type.id,
      unit_id: twu.unit.id,
      country_id: dividend_value.country_id,
      year: dividend_value.year,
      value: value
    }
    #puts "record #{record}"
    IndicatorValue.create!(record)
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
        new_unit_id = unit_ids_by_key[new_unit_key]
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