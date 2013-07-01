class CountryGroup
  include ActiveModel::Serializers::JSON
  include ::CountrySorter

  attr_accessor :title, :countries

  self.include_root_in_json = false

  def initialize(title = nil, *countries)
    @title     = title
    @countries = countries.flatten
  end

  def attributes
    {
      title: @title
    }
  end

  def serializable_hash(options={})
    options = {} if options.nil?
    options[:include] = [:countries]
    hash = super(options)
    hash['type'] = "CountryGroup"
    hash
  end

  def country_ids
    countries.map &:id
  end

  def group_id
    countries.map(&:id).sort.join('-')
  end

  def iso3
    countries.map(&:iso3).sort.join('-')
  end

end