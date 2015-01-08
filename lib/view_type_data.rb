module ViewTypeData

  def self.units
    Unit.all.as_json(only: [:key, :representation])
  end

  def self.data_types
    DataType.all.map do |data_type|
      {
        key: data_type.key,
        parent: data_type.parent_key,
        units: data_type.units.ordered_by_position.pluck(:key)
      }
    end
  end

  def self.indicator_types
    IndicatorType.external.map do |indicator_type|
      {
        key: indicator_type.key,
        group: indicator_type.group,
        units: indicator_type.units.ordered_by_position.pluck(:key)
      }
    end
  end

  def self.countries
    Country.all.map do |country|
      {
        iso3: country.iso3
      }
    end
  end

  def self.country_groups
    CountryImporter.country_groups
  end

end
