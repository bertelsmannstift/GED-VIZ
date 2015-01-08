namespace :importer do

  # Meta tasks

  desc 'Import ALL the types'
  task :import_types => [:import_data_types, :import_indicator_types]

  desc 'Import ALL the values'
  task :import_values => [:import_data_values, :import_indicator_values]

  # Bilateral data types and values

  desc 'Import data types'
  task :import_data_types => :environment do
    DataTypeImporter.new.import
    flush_caches
  end

  desc 'Import data values'
  task :import_data_values => :environment do
    DataValueImporter.new.import
    flush_caches
  end

  # Unilateral indicator types and values

  desc 'Import indicator types and values'
  task :import_indicators => :environment do
    IndicatorTypeImporter.new.import
    IndicatorValueImporter.new.import
    flush_caches
  end

  desc 'Import indicator types'
  task :import_indicator_types => :environment do
    IndicatorTypeImporter.new.import
    flush_caches
  end

  desc 'Import indicator values'
  task :import_indicator_values => :environment do
    IndicatorValueImporter.new.import
    flush_caches
  end

  # Countries

  desc 'Import countries'
  task :import_countries => :environment do
    CountryImporter.new.import
    flush_caches
  end

  # Cache

  desc 'Flush caches'
  task :flush_caches => :environment do
    sh 'echo "flush_all" | nc 10.0.15.68 11211'
  end

  def flush_caches
    if %w(production staging).include?(ENV['RAILS_ENV'])
      Rake::Task['importer:flush_caches'].execute
    end
  end

end