class Country < ActiveRecord::Base
  has_many :indicator_values
  include ::CountrySorter

  def serializable_hash(options={})
    if options.nil?
      options = { only: [:iso3] }
    else
      options = options.dup
      options[:only] ||= [:iso3]
    end
    hash = super(options)
    hash['type'] = 'Country'
    hash
  end

  def countries
    [self]
  end

  def country_ids
    [id]
  end

  def group_id
    id.to_s
  end

  def self.from_json(json_hash)
    json_hash = json_hash.symbolize_keys
    if json_hash[:type] == "Country"
      Country.where(iso3: json_hash[:iso3]).first
    else
      CountryGroup.new(json_hash[:title], json_hash[:countries].map { |cc|
        cc = cc.symbolize_keys
        Country.where(iso3: cc[:iso3]).first
      })
    end
  end

end