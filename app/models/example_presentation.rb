class ExamplePresentation < Presentation

  def self.cached_instance
    key = 'example_presentation'
    presentation = Rails.cache.read(key)
    unless presentation
      presentation = self.new
      # Trigger serialization so the presentation includes all data
      presentation.to_json
      Rails.cache.write(key, presentation)
    end
    presentation
  end

  def initialize
    super

    self.title = 'Example Presentation'

    k = Keyframe.new
    k.title = 'Start configuration'
    k.year = 2010

    # Example country sets
    #two_countries  = Country.where(iso3: %w(deu gbr)).all
    #few_countries = Country.where(iso3: %w(deu ita gbr fra)).all
    #many_countries = Country.where(iso3: %w(deu fra gbr usa grc ind jpn can)).all
    #country_group  = CountryGroup.new("BeNeLux", Country.where(iso3: %w(bel lux nld)).all)
    start_countries = %w(usa chn jpn deu fra).map do |iso3|
      Country.find_by_iso3 iso3
    end
    k.countries = start_countries

    # Bilateral data (claims, migration, import)
    import = DataType.find_by_key 'import'
    bln_current_dollars = Unit.find_by_key 'bln_current_dollars'
    k.set_data_type_with_unit(import, bln_current_dollars)

    # Unilateral indicators
    gdp = IndicatorType.find_by_key 'gdp'
    bln_real_dollars = Unit.find_by_key 'bln_real_dollars'
    k.add_indicator_type_with_unit(gdp, bln_real_dollars)

    population = IndicatorType.find_by_key 'population'
    mln_persons = Unit.find_by_key 'mln_persons'
    k.add_indicator_type_with_unit(population, mln_persons)

    self.keyframes << k

    # k = Keyframe.new
    # k.title = 'Trade 2008'
    # k.year = 2008
    # k.set_data_type_with_unit(import, bln_current_dollars)
    # k.countries = few_countries + [country_group]
    # k.locking = 'deu'
    # self.keyframes << k
    #
    # k = Keyframe.new
    # k.title = 'Trade 2009'
    # k.year = 2009
    # k.set_data_type_with_unit(import, bln_current_dollars)
    # k.countries = many_countries + [country_group]
    # k.locking = ['deu', 'fra']
    # self.keyframes << k
  end

end