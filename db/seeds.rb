# encoding: UTF-8
require 'csv'

CountryImporter.new.import

# Relation data
DataTypeImporter.new.import
DataValueImporter.new.import

# Unilateral indicators
IndicatorTypeImporter.new.import
IndicatorValueImporter.new.import

# Clean assets and caches
[['tmp','assets'], ['tmp','cache'], ['public', 'assets']].each do |path|
  Rails.root.join(*path).tap do |dir|
    dir.rmtree if dir.exist?
  end
end
