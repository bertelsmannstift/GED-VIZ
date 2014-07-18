require 'csv'
require 'zip'

class PresentationExporter

  def initialize(presentation, keyframe_indices = nil)
    @presentation = presentation
    @keyframe_indices = keyframe_indices || (0...@presentation.keyframes.length).to_a
    @subset = keyframe_indices.nil? ? :all : :some
  end

  def export_csv_zip
    ::Zip::OutputStream.write_buffer do |zos|
      csvs.each_with_index do |csv, index|
        filename_in_zip = "#{keyframe_filename(index)}.csv"
        zos.put_next_entry(filename_in_zip)
        zos.puts(csv)
      end
    end.string
  end

  def export_images_zip(options = {})
    renderer = PresentationRenderer.new(@presentation)
    rendered = renderer.rendered?(@keyframe_indices.last, options)
    rendered = renderer.render(options) unless rendered
    return false unless rendered

    zip_path = renderer.directory.join(images_zip_filename(options))
    unless zip_path.exist?
      Rails.logger.info("Creating export zip #{zip_path}")
      ::Zip::File.open(zip_path, true) do |zip_file|
        @keyframe_indices.each do |index|
          file_path = renderer.image_path(index.to_i, options)
          filename_in_zip = "#{keyframe_filename(index)}.png"
          zip_file.add(filename_in_zip, file_path)
        end
      end
    end

    zip_path
  end

  # External filename for the downloaded file
  def public_filename(type)
    type = type.to_sym
    time = Time.now.strftime('%y%m%d')
    if type == :data
      "GEDVIZ-Data-#{time}-#{@presentation.id}.zip"
    elsif type == :image
      "GEDVIZ-Static-#{time}-#{@presentation.id}.zip"
    else
      raise "Unknown type for filename: #{type}"
    end
  end

  private

  def csvs
    keyframes.map do |keyframe|
      CSV.generate do |csv|
        # Header row
        csv << %w(country_from country_to year type unit value)

        # Data
        data_values(keyframe).each do |data_value|
          csv << [
              data_value.country_from.iso3,
              data_value.country_to.iso3,
              keyframe.year,
              keyframe.data_type_with_unit.type.key,
              keyframe.data_type_with_unit.unit.key,
              data_value.value
          ]
        end

        # Indicators
        keyframe.indicator_types_with_unit.each_with_index do |twu, indicator_index|
          keyframe.countries.each_with_index do |country, country_index|
            value = keyframe.elements[country_index].indicators[indicator_index][:value]
            csv << [
                country.countries.map(&:iso3).join(' '),
                nil,
                keyframe.year,
                twu.type.key,
                twu.unit.key,
                value
            ]
          end
        end

      end #generate
    end #map
  end #def

  def keyframes
    @keyframes ||= @keyframe_indices.map do |index|
      @presentation.keyframes[index.to_i]
    end
  end

  def data_values(keyframe)
    DataValue.where(
        year:            keyframe.year,
        data_type_id:    keyframe.data_type_with_unit.type.id,
        unit_id:         keyframe.data_type_with_unit.unit.id,
        country_from_id: keyframe.all_country_ids,
        country_to_id:   keyframe.all_country_ids
    ).where("country_to_id != country_from_id")
  end

  # Basename for a file in the ZIP file
  def keyframe_filename(index)
    index = index.to_i
    data = I18n.t(
      @presentation.keyframes[index].data_type_with_unit.type.key,
      scope: [:gedviz, :data_type]
    )
    data = data.parameterize
    year = @presentation.keyframes[index].year
    "GEDVIZ-Slide-#{index + 1}-#{data}-#{year}"
  end

  # Internal file name for the cached file
  def images_zip_filename(options)
    options_string = [
      options[:locale],
      options[:size],
      options[:show_titles] ? 1 : 0,
      options[:show_legend] ? 1 : 0
    ].join('_')
    indices = @subset == :some ? "_#{@keyframe_indices.join('-')}" : ''
    "presentation_#{@presentation.id}_images_#{options_string}#{indices}.zip"
  end

end