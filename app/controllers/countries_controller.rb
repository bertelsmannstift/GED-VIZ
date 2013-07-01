class CountriesController < ApplicationController

  def sort
    countries = params[:countries].map { |c| Country.from_json(c) }
    year = params[:year]

    sorted_countries = if params[:type] == 'data'
      data_type_with_unit = TypeWithUnit.new.tap do |twu|
        twu.set_data_type_and_unit params[:type_with_unit]
      end
      direction = params[:direction].try(&:to_sym)

      CountrySorter.sort_by_data_type(countries, year, data_type_with_unit, direction)
    else
      indicator_type_with_unit = TypeWithUnit.new.tap do |twu|
        twu.set_indicator_type_and_unit params[:type_with_unit]
      end

      CountrySorter.sort_by_indicator_type(countries, year, indicator_type_with_unit)
    end

    render json: sorted_countries.as_json
  end

  def partners
    country = Country.from_json(params[:country])
    year = params[:year]
    data_type_with_unit = TypeWithUnit.new.tap do |twu|
      twu.set_data_type_and_unit(params[:data_type_with_unit])
    end
    direction = params[:direction].try(&:to_sym)

    sorted_countries = country.biggest_partners(year, data_type_with_unit, direction)

    render json: sorted_countries.as_json
  end

end