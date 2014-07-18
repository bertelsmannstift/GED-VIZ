class Country < ActiveRecord::Base
  has_many :indicator_values
  include ::CountrySorter

  def self.from_json(hash)
    hash = hash.symbolize_keys
    if hash[:type] == 'Country'
      Country.where(iso3: hash[:iso3]).first

    elsif hash[:type] == 'CountryGroup'
      countries = hash[:countries].map do |country_hash|
        country_hash = country_hash.symbolize_keys
        Country.where(iso3: country_hash[:iso3]).first
      end
      CountryGroup.new(hash[:title], countries)
    end
  end

  def as_json(options = nil)
    {
      type: 'Country',
      iso3: iso3
    }
  end

  def countries
    [self]
  end

  def country_ids
    [id]
  end

  # Similar to CountryGroup#group_id, return the country id as a string
  def group_id
    id.to_s
  end

end