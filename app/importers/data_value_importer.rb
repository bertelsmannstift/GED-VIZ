require 'currency_converter'

class DataValueImporter < Importer

  # The main import file
  INPUT_FILENAME = 'Prognos_out_bilateral_12maerz13.csv'

  attr_reader :country_ids, :type_ids, :unit_ids, :unit_key_by_id, :unit_id_by_key

  def setup
    @country_ids = Hash.new do |hash, iso3|
      hash[iso3] = Country.find_by_iso3!(iso3).id
    end
    @type_ids = Hash.new do |hash, data_type_name|
      data_type_key = DataTypeImporter::TYPE_NAME_TO_KEY.fetch(data_type_name)
      hash[data_type_name] = DataType.find_by_key!(data_type_key).id
    end
    @unit_ids = Hash.new do |hash, unit_name|
      unit_key = DataTypeImporter::UNIT_NAME_TO_ATTRIBUTES.fetch(unit_name)[:key]
      hash[unit_name] = Unit.find_by_key!(unit_key).id
    end

    @unit_key_by_id = Hash.new do |hash, unit_id|
      hash[unit_id] = Unit.find(unit_id).key
    end
    @unit_id_by_key = Hash.new do |hash, unit_key|
      hash[unit_key] = Unit.find_by_key!(unit_key).id
    end
  end

  def import
    puts 'DataValueImporter#import'

    puts 'DataValue.delete_all'
    DataValue.delete_all

    puts 'process CSV'
    last_data_type_name = ''
    file = folder.join(INPUT_FILENAME)
    CSV.foreach(file, headers: true, return_headers: false, col_sep: ';') do |row|
      # Land;Partner;Variable;Einheit;Jahr;Wert;
      # ARG;World;Import;Mrd. US-$;2000;25.3;
      break unless row[0] and row[1]

      to_iso3    = row[0].downcase
      from_iso3  = row[1].downcase

      next if from_iso3 == '' || to_iso3 == '' ||

      # Ignore empty sums
      next if from_iso3 == 'world' || from_iso3 == 'total'

      data_type_name = row[2]
      unit_name = row[3]

      data_type_id = type_ids[data_type_name]
      unit_id      = unit_ids[unit_name]

      year  = row[4]
      value = row[5].to_f

      begin
        if data_type_name == 'Foreign Claims'
          # Switch from and to countries
          # ITA;USA;Foreign Claims;Mio. US-$;2010;36074;BIS
          # means USA owes to Italy
          to_iso3, from_iso3 = from_iso3, to_iso3

          record = {
            year:            year,
            data_type_id:    data_type_id,
            country_from_id: country_ids[from_iso3],
            country_to_id:   country_ids[to_iso3],
            unit_id:         unit_ids['Bln. US-$'],
            value:           value/1000
          }
        else
          record = {
            year:            year,
            data_type_id:    data_type_id,
            country_from_id: country_ids[from_iso3],
            country_to_id:   country_ids[to_iso3],
            unit_id:         unit_id,
            value:           value
          }
        end
        if data_type_name != last_data_type_name
          last_data_type_name = data_type_name
          puts "Importing data type: #{data_type_name}"
        end
        DataValue.create!(record)

        # Check for possible currency conversion rules
        unit_key = unit_key_by_id[record[:unit_id]]
        CurrencyConverter.convert(unit_key, year, record[:value]) do |new_value, new_unit_key|
          if new_value
            record[:unit_id] = unit_id_by_key[new_unit_key]
            record[:value] = new_value
            DataValue.create!(record)
          end
        end

      rescue Exception => e
        puts "Error importing #{row.inspect}"
        raise e
      end
    end
  end


end