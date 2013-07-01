require 'csv'
class PresentationsController < ApplicationController

  def new
    respond_to do |format|
      format.html
      format.json { render json: example_presentation }
    end
  end

  def create
    presentation = Presentation.from_json(params)
    presentation.save!
    render json: presentation.as_json
  end

  def show
    @presentation_json = Presentation.cached_json(params[:id])
    respond_to do |format|
      format.html
      format.json { render json: @presentation_json }
    end
  end

  def edit
    # Raise errors early if presentation doesn't exist
    Presentation.find(params[:id])
  end

  def export
    presentation = Presentation.find(params[:id])
    exporter = PresentationExporter.new(presentation, params[:keyframes])

    if params[:file_format] == 'csv'
      zip_string = exporter.export_csv_zip
      filename = "#{exporter.public_filename :data}.zip"
      send_data zip_string, filename: filename, type: 'application/zip'

    elsif params[:file_format] == 'image'
      options = {
        base_url: request.protocol + request.host_with_port,
        locale: I18n.locale,
        size: 'large',
        show_titles: params[:show_titles] || false,
        show_legend: params[:show_legend] || false
      }
      zip_file = exporter.export_images_zip(options)
      if zip_file
        filename = "#{exporter.public_filename :image}.zip"
        send_file zip_file, filename: filename, type: 'application/zip'
      else
        render text: 'An error occurred while generating the export ZIP.',
          status: 500
      end
    end

  end

  private

  # Create an example presentation, return its JSON serialization
  def example_presentation
    p = Rails.cache.read('example_presentation')
    return p if p

    p = Presentation.new(title: 'New Presentation')

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

    p.add_keyframe k

    # k = Keyframe.new
    # k.title = 'Trade 2008'
    # k.year = 2008
    # k.set_data_type_with_unit(import, bln_current_dollars
    # k.countries = few_countries# + [country_group]
    # k.locking = 'deu'
    # add_indicators(k)
    # p.add_keyframe k
    #
    # k = Keyframe.new
    # k.title = 'Trade 2009'
    # k.year = 2009
    # k.set_data_type_with_unit(import, bln_current_dollars
    # k.countries = many_countries + [country_group]
    # k.locking = ['deu', 'fra']
    # add_indicators(k)
    # p.add_keyframe k

    json = p.to_json
    Rails.cache.write('example_presentation', json)

    json
  end

end