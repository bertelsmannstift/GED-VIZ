class PresentationRenderer

  PHANTOMSCRIPT = Rails.root.join('script', 'render_presentation.js')
  BASEDIR = Rails.root.join('public', 'system', 'static')

  VALID_LOCALE = /^[a-z]+(-[a-z]+)?$/
  VALID_SIZES = /^(large|medium|small|thumb)$/

  attr_reader :presentation

  def initialize(presentation)
    @presentation = presentation
    raise 'Rendering only works with saved records' if @presentation.new_record?
    logfile = Rails.root.join('log', 'presentation_renderer.log')
    @logger = Logger.new(logfile, 1, 1.megabytes)
  end

  def render(options)
    check_options(options)

    @logger.info "**** Start rendering #{presentation.id} ****"
    @logger.info "Options: #{options}"

    clear!(options)
    directory.mkpath

    # Get PhantomJS command
    command = render_command(options)
    @logger.info command

    # Start PhantomJS process
    io = IO.popen(command, err: [:child, :out])
    io.each_line do |line|
      @logger.info line.strip
    end
    io.close

    # Check exist status
    raise 'PhantomJS exited with an error' if $?.exitstatus != 0

    true
  rescue => e
    @logger.error "Rendering error: #{e}"
    clear!(options)
    false
  ensure
    @logger.info "**** Finished rendering #{presentation.id} ****"
  end

  def rendered?(keyframe_index, options)
    image_path(keyframe_index, options).exist?
  end

  def clear!(options = nil)
    if options
      options_string = options_to_string(options)
      Pathname.glob(directory.join("*_#{options_string}.png")).each &:delete
    else
      directory.rmtree if directory.exist?
    end
  end

  def image_path(keyframe_index, options)
    options_string = options_to_string(options)
    filename = 'keyframe_%04d_%s.png' % [keyframe_index, options_string]
    directory.join(filename)
  end

  def directory
    BASEDIR.join(presentation.id.to_s)
  end

  private

  def render_command(options)
    binary = 'phantomjs' # Path to phantomjs binary
    [
      binary,
      PHANTOMSCRIPT,
      directory,
      presentation.id,
      options[:base_url],
      options[:locale],
      options[:size],
      options[:show_titles] ? 1 : 0,
      options[:show_legend] ? 1 : 0,
    ].join(' ')
  end

  def options_to_string(options)
    check_options(options)
    [
      options[:locale],
      options[:size],
      options[:show_titles] ? 1 : 0,
      options[:show_legend] ? 1 : 0
    ].join('_')
  end

  def check_options(options)
    unless options[:locale] =~ VALID_LOCALE
      raise "Invalid locale #{options[:locale]}"
    end
    unless options[:size] =~ VALID_SIZES
      raise "Invalid size #{options[:size]}"
    end
  end

end