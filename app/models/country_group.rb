class CountryGroup
  include ::CountrySorter

  attr_accessor :title, :countries

  def initialize(title = nil, *countries)
    @title = title
    @countries = countries.flatten
  end

  def as_json(options = nil)
    {
      type: 'CountryGroup',
      title: title,
      countries: countries
    }
  end

  def country_ids
    countries.map(&:id)
  end

  # Returns all country ids joined by a dash
  # Returns a string
  def group_id
    countries.map(&:id).sort.join('-')
  end

  # Returns all country iso3 codes joined by a dash
  def iso3
    countries.map(&:iso3).sort.join('-')
  end

end